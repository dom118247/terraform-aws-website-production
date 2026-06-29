# My Third Space — AWS Infrastructure

This is my production based project for my website [mythirdspace.co.uk](https://mythirdspace.co.uk) which is based as a UK community events platform to connect people with local venues and experiences. Built as a DevOps portfolio project demonstrating end-to-end infrastructure as code using terraform.

## What it does

- Serves a static website globally via CloudFront with HTTPS
- Accepts waitlist and venue registrations via a serverless API
- Stores signups in a managed PostgreSQL database
- Sends confirmation emails via Amazon SES
- Monitors all components with CloudWatch alarms and Grafana
- Backs up the database daily with 7-day retention

## Architecture

```
User → CloudFront (WAF + Geo restriction) → S3 (static site)
                                          → API Gateway → Lambda → RDS (PostgreSQL)
                                                                 → SES (email)
```

| Layer | Service |
|---|---|
| CDN | CloudFront (PriceClass_100 — US + Europe) |
| Security | WAF v2 (managed rulesets + IP reputation) |
| Static hosting | S3 (private, OAC access only) |
| TLS | ACM certificate (us-east-1, DNS validated) |
| DNS | Route53 (apex + www alias records) |
| API | API Gateway HTTP (v2) with CORS |
| Compute | Lambda (Python 3.12, VPC-attached) |
| Database | RDS PostgreSQL 16 (Multi-AZ, encrypted, Secrets Manager password) |
| Email | Amazon SES v2 (DKIM verified) |
| Network | VPC — 2 AZs, public/private subnets, NAT gateway per AZ |
| Monitoring | CloudWatch alarms → SNS → email, Amazon Managed Grafana |
| Backup | AWS Backup (daily 3am, 7-day retention) + S3 replica bucket (eu-west-1) |

## Repo structure

```
├── main.tf                  # root — calls all modules, wires outputs between them
├── versions.tf              # Terraform + provider version pins
├── backend.tf               # S3 remote state (us-east-1, native locking)
├── variables.tf             # input variables (region, domain, project)
├── outputs.tf               # CloudFront URL, distribution ID, S3 bucket, API endpoint
│
├── modules/
│   ├── s3/                  # website bucket (private, versioned, encrypted)
│   ├── cloudfront/          # ACM cert, OAC, distribution, bucket policy
│   ├── dns/                 # Route53 A alias records (apex + www)
│   ├── vpc/                 # VPC, subnets, NAT gateways
│   ├── security-groups/     # Lambda (egress only) + RDS (port 5432 from Lambda)
│   ├── rds/                 # PostgreSQL 16, Multi-AZ, Secrets Manager password
│   ├── ses/                 # SES domain identity + DKIM DNS records
│   ├── lambda/              # signup function, IAM role, VPC config
│   ├── api-gateway/         # HTTP API, CORS, Lambda integration
│   ├── waf/                 # WAF ACL (common ruleset + IP reputation)
│   ├── monitoring/          # CloudWatch alarms, SNS alerts, Grafana workspace
│   └── backup/              # AWS Backup vault/plan, state replica bucket
│
├── lambda/
│   ├── handler.py           # Python — handles waitlist + venue signups
│   └── signup.zip           # built by CI pipeline (pip install + zip)
│
├── index.html               # static website
│
└── .github/workflows/
    ├── terraform-plan.yml   # runs on push to main — terraform plan
    ├── terraform-apply.yml  # manual trigger — apply + upload site + invalidate cache
    └── terraform-destroy.yml # manual trigger — targeted destroy of all resources
```

## CI/CD pipeline

Authentication uses OIDC — no stored AWS credentials. GitHub Actions assumes `PipelineRole` via OIDC.

| Workflow | Trigger | What it does |
|---|---|---|
| `terraform-plan.yml` | Push to `main` | Builds Lambda zip, runs `terraform plan` |
| `terraform-apply.yml` | Manual | Builds Lambda zip, applies infrastructure, uploads `index.html` to S3, invalidates CloudFront cache |
| `terraform-destroy.yml` | Manual | Targeted destroy of all resources (excludes `prevent_destroy` buckets) |

## Key design decisions

- **OAC not OAI** — CloudFront Origin Access Control
- **S3 native locking** — `use_lockfile = true` (Terraform 1.10+), no DynamoDB needed
- **ACM in us-east-1** — CloudFront requirement; handled via provider alias
- **WAF in us-east-1** — CloudFront scope requirement; handled via provider alias
- **Secrets Manager password** — `manage_master_user_password = true` on RDS; Lambda fetches at runtime
- **Lambda in VPC** — private subnets only, egress-only security group
- **Geo restriction** — Russia, China, Iran, North Korea blocked at CloudFront
- **Multi-AZ RDS** — deletion protection + encrypted storage
- **S3 replica bucket** — state bucket replicated to eu-west-1 for disaster recovery

## State management

Remote state stored in `s3://mythirdspace-state-prod` (us-east-1). Native S3 locking via `use_lockfile = true` so no DynamoDB has been used.

The state bucket itself is not managed here. It is provisioned by a separate private base environment repository that handles my AWS infrastructure shared across all present and future projects including the S3 state bucket, OIDC provider and IAM pipeline roles. This separation means the base security layer is established once and independently of any individual project, following the principle that the foundation should never depend on what it supports.
