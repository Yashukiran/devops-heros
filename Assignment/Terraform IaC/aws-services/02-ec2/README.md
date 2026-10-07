# 02 – EC2 (Elastic Compute Cloud) · Compute

## What is EC2?
EC2 provides **virtual servers (instances)** in the AWS cloud. You choose the OS, CPU, memory, storage and networking, start it in minutes, and pay per second while it runs. It's IaaS: AWS manages the hardware, you manage the OS and everything above it.

## AMI (Amazon Machine Image)
- The **template** an instance boots from: the OS + preinstalled software + root volume snapshot + launch permissions.
- Sources: AWS (Amazon Linux 2023, Ubuntu, Windows), AWS Marketplace (vendor images), or **your own custom AMIs** (golden images built with Packer).
- AMIs are **regional**. Copy them to use in another region.

## Instance types
Named like `t3.micro` = **family** `t` + **generation** `3` + **size** `micro`.

| Family | Optimized for | Examples |
|---|---|---|
| General purpose | balanced | `t3` / `t4g` (burstable), `m7i`, `m7g` |
| Compute optimized | CPU | `c7i`, `c7g` |
| Memory optimized | RAM | `r7i`, `x2iedn` |
| Storage optimized | local disk IOPS | `i4i`, `d3` |
| Accelerated | GPU / ML | `g5`, `p5`, `inf2` |

A `g` in the name means AWS Graviton (ARM, cheaper). Pricing models: **On-Demand**, **Savings Plans / Reserved** (1–3 years, up to ~72% cheaper), **Spot** (spare capacity, up to ~90% cheaper, can be interrupted).

## Key pairs
- An **SSH key pair** for logging in: AWS keeps the **public key** and puts it in the instance, and you download the **private key** (`.pem`) once.
- `ssh -i mykey.pem ec2-user@<public-ip>`
- Never share or commit the `.pem`. Modern alternative: **SSM Session Manager**, which needs no SSH keys and no open port 22.

## Security Groups
- A **stateful virtual firewall** at the instance (network interface) level.
- **Allow rules only** (no deny). Inbound is denied by default, outbound is allowed by default.
- Stateful: if inbound traffic is allowed, the reply is automatically allowed.
- Rules can reference **other security groups**, e.g. "the DB SG allows 5432 only from the App SG".

```text
web-sg: inbound 443 from 0.0.0.0/0, 22 from <my-ip>/32
app-sg: inbound 8080 from web-sg
```

## EBS (Elastic Block Store)
- **Network-attached block storage** (a virtual disk) for an instance. It lives in **one Availability Zone**.
- Persists independently of the instance (unlike the instance store, which is wiped on stop).
- Types: `gp3` (general SSD, default), `io2` (high IOPS), `st1` / `sc1` (HDD, throughput / cold).
- **Snapshots** are incremental backups stored in S3, and can be copied to other regions or turned into AMIs. Supports **encryption** with KMS.

## Public vs private IP
| | Private IP | Public IP | Elastic IP |
|---|---|---|---|
| Reachable from | inside the VPC | the internet | the internet |
| Assigned | always, from the subnet CIDR | optional, in public subnets | you allocate it |
| On stop / start | **kept** | **changes** | **kept** (static) |

Instances in a **private subnet** have no public IP and reach the internet through a NAT Gateway.

## Instance lifecycle

```text
pending ──► running ──► stopping ──► stopped ──► (start) ──► pending
              │   ▲                    │
         reboot   │                    └──► terminated
              ▼   │
           rebooting           running ──► shutting-down ──► terminated
```

- **Running**: billed for compute.
- **Stopped**: no compute charge, but EBS is still billed. The public IP is released.
- **Hibernate**: RAM is saved to EBS for a faster resume.
- **Terminated**: deleted permanently. The root EBS volume is deleted by default (`DeleteOnTermination`).

## Common use cases
- Web/application servers (often behind an **Application Load Balancer** in an **Auto Scaling Group**).
- Self-managed databases, CI/CD build agents, Jenkins.
- Kubernetes worker nodes (EKS node groups).
- Batch / HPC / ML training (Spot + GPU instances).
- Lift-and-shift migration of on-prem servers.
