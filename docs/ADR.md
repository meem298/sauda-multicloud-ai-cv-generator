# Architecture Decision Records (ADR)

Project: Sauda AI CV Generator — True Multi-Cloud Infrastructure  
Updated: 2026-05-03

---

## ADR-001: Multi-Cloud Strategy — Active-Active (AWS 60% + GCP 40%)

**Decision:** Run a complete, independent stack on both AWS and GCP simultaneously, not AWS-primary with GCP as a single-service dependency.

**Why:** The user explicitly requested true multi-cloud HA. Running both stacks active-active means if either cloud has a complete regional outage, the other absorbs 100% of traffic within < 60 seconds via Route 53 failover. A single-cloud architecture cannot achieve this level of fault tolerance.

**Traffic split:** 60% AWS (primary, us-east-1) / 40% GCP (secondary, us-central1) via Route 53 weighted records + health check failover.

**Tradeoff:** 2× infrastructure cost. Justified by: no vendor lock-in, true geo-redundancy, independent failure domains (different power, network, hardware).

---

## ADR-002: Sessions — JWT Stateless (replaces Redis cross-cloud sync)

**Decision:** Encode all session state (CV questionnaire progress) inside a signed JWT returned to the client on every response. Backend is fully stateless.

**Why:** The fundamental problem of multi-cloud is session state. If AWS handles step 3 and GCP handles step 4, they must share session data. Cross-cloud Redis replication (AWS ElastiCache ↔ GCP Memorystore) adds latency, complexity, and a synchronization failure point. JWT eliminates the problem entirely: any backend on any cloud validates the JWT independently.

**JWT payload:** `{ stepIndex, data: { name, email, phone, ... }, exp, iss }`

**Redis role (both clouds):** JWT blacklist only (logout/revoke) — small, low-stakes, no cross-cloud sync needed. If Redis is unavailable, JWT validation continues (grace mode).

**Tradeoff:** JWT grows with each step (max ~500 bytes). Acceptable. JWT secret must be identical on both clouds — stored in AWS Secrets Manager and GCP Secret Manager separately.

---

## ADR-003: Compute — ECS Fargate (AWS) + Cloud Run (GCP)

**Decision:** Use ECS Fargate on AWS and Cloud Run on GCP. Same Docker image deployed to both.

**Why ECS Fargate (not EKS):** Simple Node.js app, no microservices. EKS adds $73/mo control plane + Kubernetes operational overhead for no benefit.

**Why Cloud Run (not GKE):** Cloud Run is serverless containers — no node management, scales automatically, global by default, pay-per-use. Perfect match for GCP secondary role.

**HPA equivalent:**
- AWS: ECS Service Auto Scaling (Target Tracking CPU=60%, Step Scaling on ALB RPS>500). Min 2, Max 10 tasks.
- GCP: Cloud Run auto-scaling on concurrency (80 req/instance). Min 2, Max 20 instances.

**Tradeoff:** Different compute models (ECS vs Cloud Run) require testing on both platforms. Same Dockerfile works for both — only registry differs (ECR vs Artifact Registry).

---

## ADR-004: Load Balancing — ALB + WAF (AWS) / Cloud LB + Cloud Armor (GCP)

**Decision:** Each cloud has its own load balancer and WAF layer.

**AWS:** Application Load Balancer (ALB) — Layer 7, multi-AZ, with AWS WAF Web ACL (AWSManagedRulesCommonRuleSet + rate limit). CloudFront as edge CDN with a second WAF.

**GCP:** Cloud Load Balancing — Global Anycast IP, SSL termination, with Cloud Armor (DDoS protection + OWASP rules + rate limiting). Cloud CDN attached.

**Why two WAF layers on AWS:** CloudFront WAF blocks at the edge globally. ALB WAF adds defense-in-depth if CloudFront is bypassed. Satisfies CLAUDE.md security requirement.

**Tradeoff:** WAF costs ~$5/mo per Web ACL. Total ~$20/mo across both clouds for 4 WAF ACLs.

---

## ADR-005: DNS & Failover — Route 53 Weighted + Health Checks

**Decision:** Route 53 manages global DNS with weighted routing (60% AWS / 40% GCP) and health check failover.

**How failover works:**
1. Route 53 polls both ALB (`/health`) and GCP LB (`/health`) every 10 seconds
2. Failure threshold: 3 consecutive failures → remove from DNS
3. TTL: 30 seconds → full failover in < 60 seconds
4. Surviving cloud auto-scales to handle 100% load

**RPO = 0:** JWT is stateless — no session data to lose during failover.

**RTO < 60 seconds:** DNS TTL 30s + health check failure detection ~30s.

**Tradeoff:** Route 53 health check cost: $0.50/check/month × 2 checks = $1/month. Negligible.

---

## ADR-006: Storage — Independent Per-Cloud (no cross-cloud replication)

**Decision:** Each cloud stores PDFs in its own bucket (S3 or Cloud Storage). No replication between clouds.

**Why:** When ECS (AWS) generates a PDF → stored in S3 → pre-signed URL returned. When Cloud Run (GCP) generates a PDF → stored in Cloud Storage → signed URL returned. User downloads from whichever cloud generated their CV. No cross-cloud sync needed.

**Tradeoff:** PDFs not available cross-cloud. If user's session lands on GCP and they try to re-download, the URL points to Cloud Storage. URLs are 15-minute expiry — user should download immediately. If URL expires, user re-generates the CV.

**Frontend:** AWS: S3 + CloudFront. GCP: Cloud Storage + Cloud CDN. Same static files deployed to both.

---

## ADR-007: AI — Vertex AI Called from Both Clouds

**Decision:** Both ECS (AWS) and Cloud Run (GCP) call the same Vertex AI endpoint for CV enhancement.

**Why:** Vertex AI (gemini-1.5-flash) is the chosen AI service. Both clouds authenticate with the same GCP Service Account JSON — stored in AWS Secrets Manager (for ECS) and GCP Secret Manager (for Cloud Run).

**GCP justification (CLAUDE.md requirement):** Vertex AI (Gemini Flash) at $0.075/1M tokens is the most cost-effective generative model for CV text enhancement. AWS Bedrock Claude Haiku is comparable but more expensive at this scale.

**Tradeoff:** Cross-cloud API call from ECS → GCP adds ~50-80ms latency. Acceptable for a non-real-time enhancement step.

---

## ADR-008: Secrets Management — AWS Secrets Manager + GCP Secret Manager

**Decision:** AWS secrets in AWS Secrets Manager. GCP secrets in GCP Secret Manager. JWT secret stored in both.

**Why:** Never hardcode secrets. Each cloud's runtime reads from its native secrets service (ECS → Secrets Manager via VPC Endpoint; Cloud Run → Secret Manager via environment secret binding). Cross-cloud secrets (JWT) duplicated in both services — synchronization done manually during setup.

**Tradeoff:** JWT secret must be kept in sync between clouds if rotated. Documented in DEPLOY.md. Auto-rotation not enabled by default.

---

## ADR-009: Networking — VPC Endpoints (dev) / NAT Gateway (prod)

**Decision:** Dev uses VPC Endpoints (S3 Gateway + ECR/SM/CW Interface) instead of NAT Gateway. Prod uses NAT Gateway.

**AWS dev:** ECS tasks in private subnets reach AWS APIs via VPC Endpoints (no internet). Vertex AI calls go through the ECS security group egress rule (HTTPS to 0.0.0.0/0). Cost saving: ~$13/month vs NAT.

**GCP dev:** Cloud Run with VPC Connector. No Cloud NAT — Cloud Run can reach internet by default. Cloud NAT added in prod for consistent egress IP (useful for IP allowlisting).

**Why NAT in prod:** Prod ECS tasks may need outbound internet for Vertex AI + any future integrations. NAT provides a static egress IP for allowlisting.

---

## ADR-010: Terraform State — S3 + DynamoDB (AWS-hosted, both clouds)

**Decision:** Single Terraform state backend (S3 + DynamoDB in AWS) manages both AWS and GCP resources.

**Why:** Standard pattern. S3 versioning enables state rollback. DynamoDB prevents concurrent applies. Both providers (AWS + Google) are managed in one Terraform workspace per environment.

**Bootstrap order:** Run `infra/global/state-backend/` first (local state) → creates S3 + DynamoDB → all other environments use remote backend.

**Tradeoff:** GCP state stored in AWS. Acceptable — Terraform state is not a security boundary (it contains resource IDs, not credentials).

---

## ADR-011: CI/CD — Lint + Format Check Only (no auto-apply)

**Decision:** GitHub Actions runs `terraform fmt -check` + tflint (AWS + GCP rulesets) + Dockerfile hadolint on every PR. No `terraform apply` in CI.

**Why:** Auto-apply against production requires approval gates, state locking, and rollback automation. Out of scope for initial project. Manual deploy following DEPLOY.md is safer and more transparent.

**Tradeoff:** Slower deployment cycle. Mitigated by comprehensive DEPLOY.md with exact commands.

---

## ADR-012: Dev vs Prod Differences

| Component | Dev | Prod |
|---|---|---|
| AWS ECS tasks | 1 / max 3 | 2 / max 10 |
| AWS task size | 0.25 vCPU · 512 MB | 0.5 vCPU · 1 GB |
| GCP Cloud Run | 1 / max 5 instances | 2 / max 20 instances |
| GCP CPU | 1 (idle between requests) | 2 (always allocated) |
| NAT Gateway (AWS) | ❌ VPC Endpoints only | ✅ |
| Cloud NAT (GCP) | ❌ | ✅ |
| Log retention | 7 days | 90 days |
| S3 / GCS versioning | ❌ | ✅ |
| Deletion protection | ❌ | ✅ |
| WAF rate limit | 1000 req/5min | 500 req/5min |
| Route 53 weighted routing | Single target (dev only) | 60/40 + failover |
| Est. monthly cost | ~$40/mo | ~$120/mo |
