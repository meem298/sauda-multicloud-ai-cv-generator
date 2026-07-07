> **gemini-1.5-flash:** $0.075/1M input tokens · $0.30/1M output tokens

# COST.md — Monthly Cost Estimation (ECS Fargate Architecture)

> **Pricing Basis:** us-east-1 (AWS) & us-central1 (GCP) — May 2026.
> **Architecture:** ECS Fargate primary compute + serverless data layer.

---

## 🟢 Dev Environment — Monthly Estimate: ~$83 | 2-Day Run: ~$5.53

### AWS Dev Breakdown
| Service | Status | Details | Cost/Month |
|:---|:---|:---|:---|
| **ECS Fargate** | 💰 Paid | 1 task · 0.25 vCPU / 512 MB · 730h | ~$13 |
| **ALB** | 💰 Paid | $16.20/mo base + ~$0.008/LCU-hr | ~$17 |
| **NAT Gateway** | 💰 Paid | 1 AZ · $32/mo ($0.045/hr + $0.045/GB) | ~$32 |
| **DynamoDB** | ✅ Always Free | 25GB + 25 WCU/RCU free | $0 |
| **S3 (Frontend + PDFs)** | ✅ Free Tier | 5GB free (first 12 months) | $0 |
| **CloudFront** | ✅ Always Free | 1TB/month data transfer free | $0 |
| **WAF (CloudFront)** | 💰 Paid | $5 Web ACL + $1 per rule | $6 |
| **Secrets Manager** | 💰 Paid | 2 secrets × $0.40 | $0.80 |
| **Route 53** | 💰 Paid | 2 health checks × $0.50 | $1 |
| **CloudWatch** | ✅ Mostly Free | 5GB logs free | ~$0 |
| **ECR** | ✅ Always Free | 500MB storage free | $0 |
| **AWS Dev Total** | | | **~$70** |

### GCP Dev Breakdown
| Service | Status | Details | Cost/Month |
|:---|:---|:---|:---|
| **Cloud Run** | ✅ Always Free | 2M req/mo + 360K GB-sec free | $0 |
| **Firestore** | ✅ Always Free | 1GB + 50K reads/day + 20K writes/day | $0 |
| **Cloud Storage** | ✅ Always Free | 5GB storage free | $0 |
| **Secret Manager** | ✅ Near-Free | 6 secrets free + minimal ops fees | $0.12 |
| **Cloud Monitoring** | ✅ Always Free | Basic metrics and monitoring | $0 |
| **Artifact Registry** | ✅ Always Free | 500MB storage free | $0 |
| **Vertex AI (Gemini Flash)**| 💰 Paid | ~500 tokens/CV × 1000 CVs/month | ~$1.00 - $3.00 |
| **GCP Dev Total** | | | **~$1.12 - $3.12** |

**Total Dev Cost: ~$71 - $73 /Month**  
**2-Day Intensive Usage: ~$4.73 - $5.53**

---

## 🔵 Prod Environment — Monthly Estimate: ~$110 - $130

### AWS Prod Details
| Service | Status | Details | Cost/Month |
|:---|:---|:---|:---|
| **ECS Fargate** | 💰 Paid | 2 tasks · 0.5 vCPU / 1GB · 730h | ~$30 |
| **ALB** | 💰 Paid | Base + production LCU usage | ~$20 |
| **NAT Gateway** | 💰 Paid | 2 AZs · $32/mo each | ~$64 |
| **DynamoDB** | ✅ Near-Free | PAY_PER_REQUEST | $0 - $2 |
| **S3** | ✅ Near-Free | Versioning enabled | ~$1 |
| **CloudFront** | ✅ Always Free | Higher production traffic | ~$0 |
| **WAF** | 💰 Paid | Standard Protection | $6 |
| **Secrets Manager** | 💰 Paid | Standard Usage | $0.80 |
| **Route 53** | 💰 Paid | Standard Health Checks | $1 |
| **AWS Prod Total** | | | **~$123 - $125** |

### GCP Prod Details
*   **Cloud Run:** 1 min instance · `cpu_always_allocated=true` (~$5/mo)
*   **Firestore:** Production traffic (likely fits in free tier) ($0 - $2/mo)
*   **Cloud Storage:** Versioning + higher operations (~$1/mo)
*   **Vertex AI:** ~10K CVs processed per month (~$5 - $10/mo)
*   **GCP Prod Total: ~$11 - $18**

**Total Prod Grand Total: ~$110 - $130 /Month** *(well within $200 budget)*

---

## 📊 Cost Comparison

| Environment | Serverless (Lambda) | ECS Fargate | Budget |
|:---|:---|:---|:---|
| **Dev / Month** | ~$9 - $11 | **~$71 - $73** | — |
| **Prod / Month** | ~$32 - $40 | **~$110 - $130** | $200 ✅ |
| **Dev / 2-Day Run** | ~$0.60 - $0.72 | **~$4.73 - $5.53** | — |

> **Why ECS Fargate?** No cold starts, persistent Express.js process, real horizontal autoscaling (1→10 tasks), and full VPC isolation. Tradeoff: NAT Gateways add ~$32/AZ/month.

---

## 📦 ECS Fargate Sizing Reference

| Environment | vCPU | Memory | Tasks | Monthly Fargate Cost |
|:---|:---|:---|:---|:---|
| Dev | 0.25 | 512 MB | 1 | ~$13 |
| Prod | 0.5 | 1 GB | 2 (min) | ~$30 |

*Fargate pricing: $0.04048/vCPU-hr + $0.004445/GB-hr (us-east-1)*

---

## ✂️ Retired Services (Cost Savings vs Legacy)

| Service Removed | Previous Cost | Current Alternative |
|:---|:---|:---|
| GCP VPC Connector | $144/mo | None — Cloud Run accesses Firestore directly |
| GCP Cloud Load Balancer | $18/mo | Cloud Run Direct HTTPS (Free) |
| GCP Memorystore Redis | $15/mo | Firestore (Always Free) |
| AWS ElastiCache Redis | $19/mo | DynamoDB (Always Free) |
| AWS WAF (ALB Regional) | $6/mo | Consolidated WAF on CloudFront |
| **Legacy Savings Still Active** | **$202 /mo** | |

---

## 🛡️ Always Free Tier — Usage Limits to Watch

| Service | Free Tier Limit | Expected Usage (Dev) | Status |
|:---|:---|:---|:---|
| Lambda | 1M req + 400K GB-sec/mo | < 50K requests | ✅ Safe |
| API Gateway | 1M calls/mo | < 50K calls | ✅ Safe |
| DynamoDB | 25GB storage + 25 WCU/RCU | < 1GB, < 1K ops/day | ✅ Safe |
| Cloud Run | 2M req/mo + 360K GB-sec | < 50K requests | ✅ Safe |
| Firestore | 1GB + 50K reads/day | < 1K ops/day | ✅ Safe |

---

## 🤖 Vertex AI (Gemini 1.5 Flash) Pricing Details

| Processing Volume | Input Tokens | Output Tokens | Daily Cost | Monthly Cost |
|:---|:---|:---|:---|:---|
| 100 CVs / Day | ~50K tokens | ~30K tokens | ~$0.04 | **~$1.2** |
| 1000 CVs / Day | ~500K tokens | ~300K tokens | ~$0.35 | **~$10.5** |

*Note: Pricing based on $0.075/1M input and $0.30/1M output tokens.*

---

## ⚠️ Mandatory Budget Alerts

```bash
# AWS: Trigger Alert at $30
# Console: Billing -> Budgets -> Create Budget -> Fixed Cost -> $30

# GCP: Trigger Alert at $30
# Console: Billing -> Budgets & Alerts -> Create Budget -> $30