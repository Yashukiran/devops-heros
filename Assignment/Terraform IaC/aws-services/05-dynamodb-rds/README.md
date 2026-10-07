# 05 – DynamoDB & RDS · Database Services

AWS's two main managed databases:
- **DynamoDB**: NoSQL key-value. Any scale, single-digit-millisecond latency, serverless.
- **RDS / Aurora**: relational SQL. Joins, transactions and a fixed schema.

---

## DynamoDB

### NoSQL
DynamoDB is a **fully managed, serverless NoSQL key-value and document database**. There are no servers to manage, it scales automatically to millions of requests per second, and it gives **single-digit-millisecond** latency at any size. There's no fixed schema (apart from the key) and no joins. You design the table around your **access patterns**.

### Tables
- A collection of items. You only define the **primary key** when you create it. Every other attribute is flexible.
- Capacity modes: **On-Demand** (pay per request, no planning) or **Provisioned** (set read/write capacity units, with auto scaling).
- Data is replicated across 3 AZs automatically. **Global Tables** give multi-region, active-active replication.

### Items
- A **row / record**, up to **400 KB**. Items in the same table can have different attributes.

### Attributes
- Name–value pairs inside an item. Types: scalar (`S` string, `N` number, `B` binary, `BOOL`, `NULL`), document (`M` map, `L` list) and sets (`SS`, `NS`, `BS`).

```json
{ "UserId": "u#1001", "OrderDate": "2026-10-07", "Total": 499, "Items": ["book", "pen"], "Status": "SHIPPED" }
```

### Partition key
- **Required.** DynamoDB hashes it to decide **which partition stores the item**.
- With only a partition key, it must be **unique** per item.
- Choose a **high-cardinality** key (e.g. `UserId`) so traffic spreads evenly. A low-cardinality key (e.g. `Status`) creates "hot partitions".

### Sort key
- **Optional**. Partition key + sort key together form a **composite primary key**.
- Items with the same partition key are stored **sorted by the sort key**, which allows range queries such as `UserId = "u#1001" AND OrderDate BETWEEN "2026-01-01" AND "2026-12-31"`.
- **Secondary indexes (GSI / LSI)** give alternative keys for other query patterns.

### Use cases
- User profiles, sessions and shopping carts.
- Gaming leaderboards, IoT telemetry, ad tech.
- High-traffic serverless APIs (API Gateway + Lambda + DynamoDB).
- Terraform state locking (the classic S3 backend + DynamoDB lock table).
- Event-driven apps with **DynamoDB Streams**.

---

## RDS (Relational Database Service)

### Relational database
RDS runs **managed relational (SQL) databases**. AWS handles provisioning, OS and DB patching, backups, failover and monitoring, and you just use the database. Relational = tables with a fixed schema, **SQL**, **joins**, foreign keys and **ACID transactions**.

### Supported engines
- **MySQL**, **PostgreSQL**, **MariaDB**
- **Oracle**, **Microsoft SQL Server**, **IBM Db2**
- **Amazon Aurora**:
  - MySQL- and PostgreSQL-compatible, built by AWS for the cloud.
  - Storage grows automatically up to 128 TB, kept as 6 copies across 3 AZs.
  - Aurora Serverless v2 scales capacity up and down automatically.

### DB instances
- An isolated database environment running on a **DB instance class** (e.g. `db.t4g.micro`, `db.r7g.large`) with **EBS storage** (gp3 / io2, which can auto-scale).
- Lives in a **DB subnet group** (private subnets in at least 2 AZs). You connect through a normal endpoint, e.g. `mydb.xxxx.ap-south-1.rds.amazonaws.com:5432`.
- Engine settings come from **parameter groups** (and option groups).

### Security
- Run it in **private subnets**, with the **security group** allowing the DB port only from the app's security group. No public access.
- **Encryption at rest** with KMS (choose it at creation; it also covers snapshots), plus **TLS in transit**.
- **IAM database authentication** (no passwords), or **Secrets Manager** to store and rotate the master password.
- Monitoring and audit: CloudTrail, Enhanced Monitoring, Performance Insights, Database Activity Streams.

### Backups
- **Automated backups**: a daily snapshot + transaction logs, kept for 1–35 days → **point-in-time restore** to any second in that window.
- **Manual snapshots**: kept until you delete them, and can be copied to other regions or accounts.
- Restoring always creates a **new** DB instance.

### Multi-AZ
- Keeps a **synchronous standby** in another AZ (or 2 readable standbys in a Multi-AZ *cluster*).
- **Automatic failover** (about 1–2 minutes) when the primary or its AZ fails, or during patching. The endpoint name stays the same.
- This is for **high availability**, not for scaling reads (the classic standby can't be read).

### Read replicas
- **Asynchronous** copies (up to 15) in the same or other regions, used to **scale read traffic** (reports, analytics).
- Each one has its own endpoint, and the app sends reads there.
- They can be **promoted** to a standalone database (e.g. for cross-region disaster recovery).

| | Multi-AZ | Read replica |
|---|---|---|
| Purpose | availability / failover | read scaling (and DR) |
| Replication | synchronous | asynchronous |
| Readable | no (classic standby) | yes |
| Failover | automatic | manual promote |

### Use cases
- Web/e-commerce applications, ERP, CRM, banking. Anything that needs **transactions, joins and a consistent schema**.
- Lift-and-shift of existing MySQL / PostgreSQL / Oracle / SQL Server databases.
- Reporting and analytics through read replicas.

---

## DynamoDB vs RDS – when to use which

| | DynamoDB | RDS / Aurora |
|---|---|---|
| Model | NoSQL key-value / document | relational tables |
| Query | by key or index (`GetItem`, `Query`) | full SQL, joins, aggregations |
| Schema | flexible (only the key is fixed) | fixed schema |
| Scaling | automatic, virtually unlimited | bigger instance + read replicas |
| Servers | serverless | DB instances (except Aurora Serverless) |
| Best for | massive scale with known access patterns | complex queries, transactions, existing SQL apps |
