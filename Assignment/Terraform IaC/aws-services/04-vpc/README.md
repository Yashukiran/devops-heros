# 04 – VPC (Virtual Private Cloud) · Networking

## What is VPC?
A VPC is your own **logically isolated private network** inside an AWS region. You define its IP range, split it into subnets, and control routing and firewalls. EC2, RDS, EKS, Lambda (in a VPC) and load balancers all live inside a VPC. Each region has a **default VPC**, but production uses custom VPCs.

```text
Region (ap-south-1)
└── VPC 10.0.0.0/16
    ├── AZ ap-south-1a
    │   ├── Public subnet  10.0.1.0/24   (load balancer, NAT gateway, bastion)
    │   └── Private subnet 10.0.11.0/24  (app servers, EKS nodes)
    └── AZ ap-south-1b
        ├── Public subnet  10.0.2.0/24
        └── Private subnet 10.0.12.0/24  (RDS standby)

  public route table  : 0.0.0.0/0 → Internet Gateway
  private route table : 0.0.0.0/0 → NAT Gateway
```

## CIDR
- **Classless Inter-Domain Routing** notation for an IP range: `10.0.0.0/16` means the first 16 bits are fixed, so there are 2^16 = **65,536** addresses.
- `/24` = 256 addresses (AWS reserves **5 per subnet**, so 251 are usable).
- A VPC can be `/16` (largest) to `/28` (smallest). Use private ranges (RFC 1918: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) that **don't overlap** with other VPCs or on-prem networks you'll connect to.

## Subnets
- A slice of the VPC CIDR in **exactly one Availability Zone**.
- Spread subnets across **at least 2 AZs** for high availability.
- A subnet is "public" or "private" only because of its **route table**.

## Route tables
- Rules that tell traffic where to go: **destination CIDR → target**.
- Every route table has the `local` route (VPC CIDR → local), so all subnets in a VPC can reach each other.

| Route table | Destination | Target |
|---|---|---|
| public-rt | 10.0.0.0/16 | local |
| public-rt | 0.0.0.0/0 | **igw-xxxx** |
| private-rt | 10.0.0.0/16 | local |
| private-rt | 0.0.0.0/0 | **nat-xxxx** |

## Internet Gateway (IGW)
- Attached to the VPC. Allows **two-way** internet traffic for resources with a **public IP** in subnets that route `0.0.0.0/0 → igw`.
- Horizontally scaled, highly available, free. One per VPC.

## NAT Gateway
- Lets instances in **private subnets** start **outbound** connections to the internet (OS updates, pulling images, calling APIs), while **blocking inbound** connections from the internet.
- Lives in a **public subnet** with an Elastic IP. Create one per AZ for HA.
- Managed, but **billed hourly + per GB**, so it's a common cost surprise. Alternatives: VPC endpoints (the S3/DynamoDB gateway endpoints are free) or NAT instances.

## Security Groups
- **Stateful** firewall at the **instance / network interface** level, with **allow rules only**.
- Can reference other security groups (e.g. the DB allows 5432 from `app-sg`).
- More detail in [02-ec2](../02-ec2/README.md#security-groups).

## Network ACLs
- **Stateless** firewall at the **subnet** level.
- **Allow *and* deny rules**, evaluated **in number order** (lowest first, first match wins).
- Stateless means **return traffic must be allowed explicitly** (ephemeral ports 1024–65535).
- The default NACL allows everything. Use NACLs for coarse subnet-wide blocks (e.g. deny a malicious IP range).

| | Security Group | Network ACL |
|---|---|---|
| Level | instance (network interface) | subnet |
| State | stateful | stateless |
| Rules | allow only | allow + deny |
| Evaluation | all rules together | in order, first match wins |
| Default | deny inbound, allow outbound | allow all (default NACL) |

## Public vs private subnet
| | Public subnet | Private subnet |
|---|---|---|
| Route to internet | `0.0.0.0/0 → Internet Gateway` | `0.0.0.0/0 → NAT Gateway` (or none) |
| Inbound from internet | possible (with public IP + SG rule) | **not possible** |
| Typical resources | load balancers, NAT gateway, bastion | app servers, databases, EKS nodes |

**Best practice:** only load balancers (and the NAT gateway) are public. Applications and databases stay private.

## Other VPC features
- **VPC Peering / Transit Gateway**: connect VPCs together.
- **Site-to-Site VPN / Direct Connect**: connect to on-prem networks.
- **VPC Endpoints / PrivateLink**: reach AWS services without going over the internet.
- **Flow Logs**: record network traffic for troubleshooting and security.
