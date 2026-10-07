# 01 – IAM (Identity and Access Management) · Governance

## What is IAM?
IAM is the AWS service that controls **who** (authentication) can do **what** (authorization) on **which** AWS resources. It's global (not per-region) and free. Every AWS API call, from the console, the CLI, Terraform or an application, is checked against IAM.

```text
Principal (user / role)  ──►  makes a request  ──►  IAM evaluates policies  ──►  Allow / Deny
```

## Users
- A long-term identity for **one person or application**.
- Signs in to the console with a password (+ MFA), or calls the API with **access keys** (Access Key ID + Secret).
- A new user has **no permissions** until a policy grants them.
- The **root user** (the account's email) can do everything. Lock it with MFA and don't use it day to day.

## Groups
- A collection of users, e.g. `Developers`, `Admins`, `ReadOnly`.
- Attach policies to the **group**, and every member inherits them. That's much easier than managing permissions per user.
- Groups can't be nested and can't be used as a principal in a policy.

## Roles
- An identity with permissions but **no long-term credentials**. Whoever *assumes* the role gets **temporary credentials** from STS that expire automatically.
- Used by:
  - **AWS services**: an EC2 instance profile, a Lambda execution role, an EKS pod role.
  - **Other accounts**: cross-account access.
  - **Federated users**: SSO / IAM Identity Center, and GitHub Actions through **OIDC**, with no stored keys.
- A role has two policies: a **trust policy** (who may assume it) and **permission policies** (what it can do).

## Policies
JSON documents that define permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::yashukiran-session18-*/*",
    "Condition": { "Bool": { "aws:SecureTransport": "true" } }
  }]
}
```

| Type | Attached to | Example |
|---|---|---|
| AWS managed | users / groups / roles | `ReadOnlyAccess`, `AmazonS3FullAccess` |
| Customer managed | users / groups / roles (reusable) | `S3-Session18-Write` |
| Inline | one identity only | rarely recommended |
| Resource-based | the resource itself | S3 bucket policy, KMS key policy |
| Permission boundary / SCP | limits the *maximum* permissions | AWS Organizations guardrails |

## Permissions: how a request is evaluated
1. Everything starts as **implicit deny**.
2. An **explicit `Deny`** anywhere always wins.
3. Otherwise an **`Allow`** in an applicable policy grants access.
4. Boundaries, SCPs and session policies can only *restrict*, never add.

## Least privilege
Give each identity **only the actions and resources it needs, for only as long as it needs them**. Start from nothing and add, rather than starting from `*` and removing. Use **IAM Access Analyzer** and "last accessed" data to remove unused permissions.

For this session's Terraform, the IAM user only needs S3 actions on `arn:aws:s3:::yashukiran-session18-*`, not `AdministratorAccess`.

## IAM best practices
- Lock away the **root user**: MFA on, no access keys, use it only for the few root-only tasks.
- **MFA** for every human user.
- Prefer **roles + temporary credentials** over long-lived access keys (IAM Identity Center for people, OIDC for CI/CD, instance roles for EC2).
- If you must use access keys: never commit them, **rotate** them, and delete unused ones.
- Grant permissions through **groups/roles**, not individual users.
- **Least privilege**, plus conditions (source IP, MFA, `aws:SecureTransport`, tags).
- Turn on **CloudTrail** to audit every API call, and review with Access Analyzer.

## Common use cases
- Team access: a `Developers` group with power-user rights, `Auditors` with `ReadOnlyAccess`.
- EC2 / Lambda reading S3 or DynamoDB through a **role**, so there are no keys in the code.
- **GitHub Actions → AWS via an OIDC role** to deploy without storing secrets.
- Cross-account access (e.g. a central security account reads logs from all accounts).
- Terraform running with a dedicated, least-privilege user or role.
