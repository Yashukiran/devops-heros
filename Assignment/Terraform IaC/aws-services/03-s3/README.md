# 03 – S3 (Simple Storage Service) · Storage

## What is S3?
S3 is AWS's **object storage**: store any amount of data as objects in buckets, accessed over HTTPS/API. It's designed for **99.999999999% (11 nines) durability** (data is stored across at least 3 Availability Zones), with virtually unlimited capacity and pay-per-GB pricing. It's *not* a file system or a disk. You `PUT`/`GET` whole objects.

> In Task 1 of this session I created a real S3 bucket with Terraform: [`../../terraform-s3-demo`](../../terraform-s3-demo).

## Buckets
- A **container for objects**. The name is **globally unique** across all AWS accounts (3–63 characters: lowercase letters, numbers, hyphens). That's why my Terraform adds a random suffix.
- Created in **one region**. Data never leaves it unless you replicate it.
- Flat namespace: "folders" are just key prefixes (`logs/2026/10/app.log`).

## Objects
- **Key** (the full name/path) + **value** (data, up to **5 TB**; use multipart upload above ~100 MB) + **metadata** + **tags** + **version ID**.
- URI: `s3://bucket/key`. URL: `https://bucket.s3.<region>.amazonaws.com/key`.
- Strong read-after-write consistency.

## Storage classes

| Class | Use for | Retrieval |
|---|---|---|
| **S3 Standard** | frequently accessed data | milliseconds |
| **S3 Intelligent-Tiering** | unknown/changing access; moves data between tiers automatically | milliseconds |
| **Standard-IA** | infrequent, but needs fast access | milliseconds (retrieval fee) |
| **One Zone-IA** | re-creatable infrequent data (1 AZ only) | milliseconds |
| **Glacier Instant Retrieval** | archive, accessed about once a quarter | milliseconds |
| **Glacier Flexible Retrieval** | archive | minutes to hours |
| **Glacier Deep Archive** | long-term compliance archive (cheapest) | ~12–48 hours |

## Versioning
- Keeps **every version** of every object. An overwrite creates a new version, and a delete only adds a *delete marker*, so you can restore it.
- Protects against accidental deletes/overwrites and ransomware. Required for replication and Object Lock.
- States: *unversioned* → *Enabled* → *Suspended* (it can never go back to unversioned).
- **I enabled it in my Terraform** (`aws_s3_bucket_versioning`).

## Lifecycle policies
Rules that automatically **transition** or **expire** objects to save cost:

```text
logs/  →  after 30 days: Standard-IA  →  after 90 days: Glacier  →  after 365 days: delete
noncurrent versions          →  delete after 60 days
incomplete multipart uploads →  abort after 7 days
```

## Encryption
- **At rest:** since 2023 every new object is encrypted by default.
  - **SSE-S3** (AES-256, keys managed by S3). **I set this explicitly in Terraform.**
  - **SSE-KMS** (your KMS key, auditable in CloudTrail, controlled by key policies).
  - **DSSE-KMS** (dual layer).
  - **SSE-C** (customer-provided key).
  - Client-side encryption.
- **In transit:** HTTPS/TLS. Enforce it with a bucket policy that denies requests where `aws:SecureTransport` is `false`.

## Bucket policies
A **resource-based JSON policy** on the bucket that controls who can access it, including other accounts or the public:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
```

**Block Public Access** (4 settings) overrides any policy or ACL that would make the bucket public. **I turned on all four in Terraform.** Prefer bucket policies + IAM over the legacy ACLs (ACLs are disabled by default now).

## Common use cases
- Static website hosting (+ CloudFront CDN).
- Backups, disaster recovery, archives (Glacier).
- **Data lakes** for analytics (Athena, Glue, EMR, Redshift Spectrum).
- Application file storage: user uploads, images, videos.
- Log storage (CloudTrail, ALB access logs, VPC Flow Logs).
- **Terraform remote state** (S3 backend with state locking).
- CI/CD artifacts and ML datasets.
