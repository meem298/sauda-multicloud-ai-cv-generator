# Sauda — Multi-Cloud AI CV Generator

A production-grade, active-active multi-cloud SaaS platform that generates ATS-optimized CVs using AI. Built on **AWS (primary, 60% traffic)** and **Google Cloud (secondary, 40% traffic)** simultaneously, with automated cross-cloud failover.

---

## Why Multi-Cloud, Active-Active

Most side projects run on a single cloud. Sauda runs a **complete, independent stack on both AWS and GCP at the same time** — not AWS-primary with GCP as a single dependency. If either cloud has a full regional outage, the other absorbs 100% of traffic within under 60 seconds via Route 53 weighted DNS + health-check failover.

This was a deliberate architectural decision (see [`docs/ADR.md`](docs/ADR.md) for the full reasoning and trade-offs), not the default or easy path — the goal was to solve the hard problems of true multi-cloud design: stateless cross-cloud sessions, independent failure domains, and cost-optimized redundancy.

---

## Architecture

```
                         Route 53 (Weighted DNS + Health Checks)
                          60% AWS  ·  40% GCP  ·  <60s failover
                                    │
              ┌─────────────────────┴─────────────────────┐
              │                                             │
        AWS (Primary)                              GCP (Secondary)
              │                                             │
      CloudFront + WAF                                Cloud CDN + Armor
              │                                             │
      ECS Fargate (API)                              Cloud Run (API)
              │                                             │
   DynamoDB · S3 · Secrets Manager             Firestore · Cloud Storage · Secret Manager
              │                                             │
         CloudWatch                                  Cloud Monitoring
```

Full diagram with service-level detail: [`docs/architecture.md`](docs/architecture.md)

**Key design principle:** stateless JWT-based sessions — any backend on either cloud can validate a request independently, eliminating the need for cross-cloud session replication.

---

## Tech Stack

| Layer | AWS | GCP |
|---|---|---|
| Compute | ECS Fargate | Cloud Run |
| Edge / Security | CloudFront + WAF | Cloud CDN + Cloud Armor |
| Database | DynamoDB | Firestore |
| Object Storage | S3 | Cloud Storage |
| Secrets | Secrets Manager | Secret Manager |
| Monitoring | CloudWatch | Cloud Monitoring |
| DNS / Failover | Route 53 (weighted + health checks) | — |
| AI | — | Vertex AI (Gemini) — CV generation |
| IaC | Terraform (modular, per-provider) | |
| CI/CD | GitHub Actions | |
| Containers | Docker | |

---

## Repository Structure

```
infra/
  ├── modules/aws/       # Reusable Terraform modules — VPC, compute, storage, security, monitoring, DNS, cache, CDN, lambda
  ├── modules/gcp/        # Reusable Terraform modules — network, compute, storage, security, monitoring, cache
  ├── environments/       # dev / prod environment configs
  └── global/             # Shared remote state backend

agent/
  ├── backend/            # Node.js API — conversational CV agent, PDF generation
  ├── frontend/           # Chat-based UI
  └── docs/               # API and flow documentation

docker/                   # Dockerfiles for backend/frontend containers
docs/
  ├── architecture.md     # Full architecture diagram + service rationale
  ├── ADR.md              # Architecture Decision Records — why, not just what
  └── PRESENTATION_SCRIPT.md

DEPLOY.md                 # Full deployment guide
RUNBOOK.md                 # Operational runbook
COST.md                    # Monthly cost breakdown (dev + prod)
```

---

## Cost Engineering

Designed free-tier-first: dev environment runs at **~$83/month**, optimized down from an initial always-on design. Full breakdown with per-service reasoning in [`COST.md`](COST.md) — including the trade-off analysis behind moving to ECS Fargate/Cloud Run for cost efficiency.

---

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — full system diagram and service-by-service rationale
- [`docs/ADR.md`](docs/ADR.md) — key architecture decisions and trade-offs (multi-cloud strategy, session management, cost vs. redundancy)
- [`DEPLOY.md`](DEPLOY.md) — step-by-step deployment guide
- [`RUNBOOK.md`](RUNBOOK.md) — operational procedures
- [`COST.md`](COST.md) — monthly cost estimation

---

## Author

**Maitha Alanzi** — Cloud Engineer (AWS Certified Solutions Architect – Associate, Google Associate Cloud Engineer)
[LinkedIn](https://linkedin.com/in/maitha-al-anzi)
