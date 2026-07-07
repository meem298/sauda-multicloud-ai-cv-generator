# Architecture — Sauda AI CV Generator
## Multi-Cloud Serverless (AWS Primary + GCP Secondary)

> **Design goal:** Always-Free-tier-first. Every service chosen has a free tier or falls within training credits ($200 AWS + $300 GCP) with < $3 total cost for 5 days.

---

## Architecture Diagram

```mermaid
graph TB
    User(["👤 User\n(Browser)"]):::user

    subgraph DNS["🌐 Global DNS — Route 53"]
        R53["⚖️ Weighted DNS\n60% AWS · 40% GCP\nHealth Check Failover\n$1/mo"]:::aws
    end

    subgraph AWS["☁️ AWS — Primary  (60% traffic)"]
        direction TB

        subgraph AWS_CDN["Edge"]
            CF["☁️ CloudFront\nWAF SQLi/XSS + Rate Limit\nAlways Free 1TB/mo\n$6/mo WAF only"]:::aws
        end

        subgraph AWS_COMPUTE["Serverless Compute"]
            APIGW["⚡ API Gateway HTTP API\nAlways Free 1M req/mo\n~$0.10/mo"]:::aws
            LM["λ Lambda\nNode.js 20.x · 512MB\nAlways Free 1M req/mo\nMulti-AZ automatic\n$0/mo"]:::aws
        end

        subgraph AWS_DATA["Data"]
            DDB["🗄️ DynamoDB\nJWT Blacklist + TTL\nAlways Free 25GB\nPAY_PER_REQUEST\n$0/mo"]:::aws
            S3P["🪣 S3 PDFs\n7-day lifecycle\nAlways Free 5GB\n~$0/mo"]:::aws
            S3F["🪣 S3 Frontend\nStatic HTML/CSS/JS\nAlways Free 5GB\n$0/mo"]:::aws
        end

        subgraph AWS_SEC["Security & Ops"]
            SM["🔐 Secrets Manager\nJWT key + Vertex AI key\n$0.80/mo"]:::aws
            CW["📊 CloudWatch\nLogs + Alarms\nFree tier\n~$0/mo"]:::aws
        end
    end

    subgraph GCP["☁️ GCP — Secondary  (40% traffic)"]
        direction TB

        subgraph GCP_COMPUTE["Serverless Compute"]
            CR["🚀 Cloud Run\nNode.js 20.x · 1CPU · 512Mi\nAlways Free 2M req/mo\nScale-to-zero in dev\n$0/mo"]:::gcp
        end

        subgraph GCP_DATA["Data"]
            FS["🔥 Firestore\nJWT Blacklist + TTL\nAlways Free 1GB · 50K reads/day\n$0/mo"]:::gcp
            GCS_P["🪣 Cloud Storage PDFs\n7-day lifecycle\nAlways Free 5GB\n$0/mo"]:::gcp
            GCS_F["🪣 Cloud Storage Frontend\nStatic HTML/CSS/JS\nAlways Free 5GB\n$0/mo"]:::gcp
        end

        subgraph GCP_SEC["Security & Ops"]
            SM_GCP["🔐 Secret Manager\nJWT key + Vertex AI key\n$0.12/mo"]:::gcp
            CM["📊 Cloud Monitoring\nLogs + Alerts\nFree basic tier\n$0/mo"]:::gcp
        end
    end

    subgraph AI["🤖 AI — Shared (GCP)"]
        VAI["✨ Vertex AI\nGemini Flash\nCV text enhancement\n~$1-5/mo dev"]:::gcp
    end

    User -->|"HTTPS"| R53
    R53 -->|"60% traffic"| CF
    R53 -->|"40% traffic"| CR
    R53 -.->|"Failover if AWS down"| CR

    CF -->|"/api/* backend"| APIGW
    CF -->|"/* static"| S3F
    APIGW --> LM
    LM --> DDB
    LM --> S3P
    LM --> SM
    LM -->|"AI enhancement"| VAI

    CR --> FS
    CR --> GCS_P
    CR --> SM_GCP
    CR -->|"AI enhancement"| VAI

    LM -.-> CW
    CR -.-> CM

    classDef aws fill:#FF9900,color:#000,stroke:#c27600,stroke-width:2px
    classDef gcp fill:#4285F4,color:#fff,stroke:#1a5cb8,stroke-width:2px
    classDef user fill:#34A853,color:#fff,stroke:#1e7e34,stroke-width:2px
```

---

## HA Features Built In

| الميزة | كيف تعمل | التكلفة |
|---|---|---|
| **Lambda Multi-AZ** | تلقائي — AWS تشغّل Lambda في أكثر من AZ | $0 |
| **Route 53 Failover** | Health check كل 10 ثوانٍ → تحويل تلقائي لـ GCP | $1/شهر |
| **CloudFront Failover Origin** | إذا API Gateway أعاد 5xx → CloudFront يحوّل لـ Cloud Run | $0 إضافي |
| **Cloud Run Traffic Split** | نشر canary وترجيع بدون downtime | $0 |
| **DynamoDB Multi-AZ** | تلقائي — DynamoDB مُوزّع داخلياً | $0 |
| **Firestore Multi-Region** | nam5 location = US multi-region | $0 |

---

## Data Flow — CV Generation

```
1. User → CloudFront/CloudRun → POST /answer
2. Lambda / Cloud Run:
   a. Verify JWT (check DynamoDB / Firestore blacklist)
   b. Process questionnaire step
   c. Final step → call Vertex AI (Gemini Flash) for CV text enhancement
   d. Generate PDF via PDFKit
   e. Upload PDF to S3 / Cloud Storage
   f. Return presigned download URL
3. User → GET /download-cv/:sessionId → presigned URL redirect
```

---

## Cost Breakdown (Dev — 5 Days)

| الخدمة | التكلفة/شهر | 5 أيام |
|---|---|---|
| Lambda + API Gateway | ~$0.10 | < $0.02 |
| DynamoDB | $0 | $0 |
| S3 + CloudFront | ~$0 | $0 |
| WAF (CloudFront) | $6 | $1 |
| Secrets Manager | $0.80 | $0.13 |
| Route 53 | $1 | $0.16 |
| Cloud Run | $0 | $0 |
| Firestore | $0 | $0 |
| Cloud Storage | $0 | $0 |
| Vertex AI | ~$3 | $0.50 |
| **المجموع** | **~$11** | **~$1.81** |

---

## Removed Services vs. Previous Architecture

| ما أُزيل | التوفير/شهر | السبب |
|---|---|---|
| GCP VPC Connector | **$144** | Cloud Run لا تحتاجه بدون Memorystore |
| GCP Cloud Load Balancing | **$18** | Cloud Run لديه HTTPS مباشر مع TLS |
| GCP Memorystore Redis HA | **$15** | استُبدل بـ Firestore (Always Free) |
| AWS ECS Fargate | **$18** | استُبدل بـ Lambda (Always Free) |
| AWS ALB | **$17** | استُبدل بـ API Gateway ($0.10/mo) |
| AWS VPC Interface Endpoints (4x) | **$29** | Lambda تعمل خارج VPC |
| AWS ElastiCache Redis | **$19** | استُبدل بـ DynamoDB (Always Free) |
| AWS WAF (ALB Regional) | **$6** | WAF على CloudFront يكفي |
| **إجمالي التوفير** | **$266/شهر** | |
