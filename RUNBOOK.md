# RUNBOOK.md — دليل التشغيل والصيانة

---

## 1. نشر إصدار جديد (Deploy New Version)

### خطوات نشر كود جديد:

```bash
# 1. بناء الـ image
docker build -f docker/backend/Dockerfile -t sauda-backend:v2.0.0 .

# 2. رفعه للـ ECR (AWS)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker tag sauda-backend:v2.0.0 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/sauda/backend:v2.0.0
docker push \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/sauda/backend:v2.0.0

# 3. رفعه لـ Artifact Registry (GCP)
docker tag sauda-backend:v2.0.0 \
  us-central1-docker.pkg.dev/<PROJECT_ID>/sauda-backend/backend:v2.0.0
docker push \
  us-central1-docker.pkg.dev/<PROJECT_ID>/sauda-backend/backend:v2.0.0

# 4. حدّث Terraform لاستخدام الـ tag الجديد
# في infra/environments/prod/terraform.tfvars أضف:
# image_tag = "v2.0.0"

# 5. طبّق التغيير
cd infra/environments/prod
terraform plan -var image_tag=v2.0.0
terraform apply -var image_tag=v2.0.0
```

**ECS يعمل Rolling Update تلقائياً** — tasks القديمة تبقى تخدم حتى تكون الجديدة healthy.  
**Cloud Run يبدّل traffic للـ revision الجديدة** بعد أن تجتاز startup probe.

---

## 2. Rollback — التراجع لإصدار سابق

### AWS (ECS):
```bash
# اعرض الـ task definitions السابقة
aws ecs list-task-definitions \
  --family-prefix sauda-backend \
  --region us-east-1

# استرجع الـ revision السابق
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --task-definition sauda-backend:<PREVIOUS_REVISION> \
  --region us-east-1

# تحقق من الـ rollback
aws ecs describe-services \
  --cluster sauda-cluster \
  --services sauda-backend \
  --region us-east-1 | grep "taskDefinition"
```

### GCP (Cloud Run):
```bash
# اعرض الـ revisions
gcloud run revisions list \
  --service sauda-backend \
  --region us-central1

# حوّل 100% للـ revision السابق
gcloud run services update-traffic sauda-backend \
  --to-revisions sauda-backend-<PREVIOUS_REVISION>=100 \
  --region us-central1
```

---

## 3. Scale — زيادة/تخفيض الـ Capacity

### زيادة يدوية (AWS ECS):
```bash
# زيادة عدد الـ tasks يدوياً (مؤقت)
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --desired-count 5 \
  --region us-east-1
```

### زيادة يدوية (GCP Cloud Run):
```bash
# زيادة الـ min instances
gcloud run services update sauda-backend \
  --min-instances 5 \
  --region us-central1
```

### تعديل حدود الـ Auto Scaling (Terraform):
```hcl
# في infra/environments/prod/terraform.tfvars
# AWS
min_capacity = 3
max_capacity = 15

# GCP (في variables)
min_instances = 3
max_instances = 30
```

```bash
cd infra/environments/prod && terraform apply
```

---

## 4. Failover Testing — اختبار الـ HA

### اختبار سقوط AWS:
```bash
# 1. أوقف الـ ECS service مؤقتاً
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --desired-count 0 \
  --region us-east-1

# 2. انتظر 30-60 ثانية
sleep 60

# 3. تحقق أن GCP يستوعب 100% من الـ traffic
curl -s "<CF_URL>/health"   # قد يفشل (CloudFront → ALB down)
curl -s "<GCR_URL>/health"  # يجب أن ينجح

# 4. تحقق من Route 53 health check
aws route53 get-health-check-status \
  --health-check-id <AWS_HC_ID>

# 5. أعد AWS
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --desired-count 2 \
  --region us-east-1
```

---

## 5. Logs — قراءة السجلات

### AWS CloudWatch:
```bash
# Tail logs مباشرة
aws logs tail /sauda/backend-aws \
  --follow \
  --region us-east-1

# فلترة الأخطاء
aws logs filter-log-events \
  --log-group-name /sauda/backend-aws \
  --filter-pattern "ERROR" \
  --region us-east-1

# آخر 100 سطر
aws logs filter-log-events \
  --log-group-name /sauda/backend-aws \
  --start-time $(date -d '-1 hour' +%s000) \
  --region us-east-1
```

### GCP Cloud Logging:
```bash
# Tail logs
gcloud logging tail \
  "resource.type=cloud_run_revision AND resource.labels.service_name=sauda-backend"

# فلترة الأخطاء
gcloud logging read \
  "resource.type=cloud_run_revision severity>=ERROR" \
  --limit 50 \
  --format json
```

---

## 6. Secrets Rotation — تجديد الأسرار

### تجديد JWT Secret:
```bash
# 1. ولّد secret جديد
NEW_JWT=$(openssl rand -base64 48)

# 2. حدّث AWS أولاً
aws secretsmanager put-secret-value \
  --secret-id sauda/jwt-secret \
  --secret-string "${NEW_JWT}" \
  --region us-east-1

# 3. حدّث GCP فوراً (لازم يكون نفس القيمة)
echo -n "${NEW_JWT}" | \
  gcloud secrets versions add sauda-jwt-secret --data-file=-

# 4. أعد تشغيل ECS tasks لتحميل الـ secret الجديد
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --force-new-deployment \
  --region us-east-1

# 5. أعد نشر Cloud Run
gcloud run services update sauda-backend \
  --region us-central1 \
  --no-traffic  # deploy بدون تحويل traffic
gcloud run services update-traffic sauda-backend \
  --to-latest \
  --region us-central1

# تحذير: المستخدمون الذين لديهم JWT قديم سيحتاجون لإعادة البدء
# هذا مقبول (JWT expiry = 1h — تأثير محدود)
```

---

## 7. Frontend Update — تحديث الواجهة

```bash
# AWS
aws s3 sync agent/frontend/ s3://sauda-frontend-prod/ --delete

# بعد التحديث — انهِ الـ cache في CloudFront
DIST_ID=$(cd infra/environments/prod && terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "<DIST_ID>")
aws cloudfront create-invalidation \
  --distribution-id ${DIST_ID} \
  --paths "/*" \
  --region us-east-1

# GCP
gsutil rsync -r -d agent/frontend/ gs://sauda-frontend-gcp-prod/
```

---

## 8. Monitoring Quick Reference

### AWS Console Links
```
CloudWatch Dashboard:
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=sauda-aws-dashboard

ECS Service:
https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/sauda-cluster/services/sauda-backend

ALB Target Health:
https://console.aws.amazon.com/ec2/home?region=us-east-1#TargetGroups
```

### GCP Console Links
```
Cloud Run Service:
https://console.cloud.google.com/run/detail/us-central1/sauda-backend

Cloud Monitoring Dashboard:
https://console.cloud.google.com/monitoring

Cloud Logging:
https://console.cloud.google.com/logs
```

### CLI Health Check السريع:
```bash
#!/usr/bin/env bash
echo "=== Sauda Health Check ==="

CF_URL=$(cd infra/environments/prod && terraform output -raw aws_cloudfront_url 2>/dev/null)
CR_URL=$(cd infra/environments/prod && terraform output -raw gcp_cloudrun_url 2>/dev/null)

echo -n "AWS CloudFront: "
curl -s -o /dev/null -w "%{http_code}" "${CF_URL}/health"
echo ""

echo -n "GCP Cloud Run:  "
curl -s -o /dev/null -w "%{http_code}" "${CR_URL}/health"
echo ""

echo -n "ECS Running Tasks: "
aws ecs describe-services \
  --cluster sauda-cluster \
  --services sauda-backend \
  --region us-east-1 \
  --query 'services[0].runningCount' \
  --output text

echo -n "Cloud Run Instances: "
gcloud run services describe sauda-backend \
  --region us-central1 \
  --format "value(status.observedGeneration)" 2>/dev/null || echo "N/A"
```

---

## 9. Terraform State Quick Commands

```bash
# عرض الـ resources في الـ state
cd infra/environments/prod
terraform state list

# عرض resource معين
terraform state show module.aws_compute.aws_ecs_service.backend

# استيراد resource موجود لم يُنشأ بـ Terraform
terraform import module.aws_vpc.aws_vpc.main <VPC_ID>

# إزالة resource من الـ state (بدون حذفه)
terraform state rm module.aws_cache.aws_elasticache_serverless_cache.redis

# تحديث الـ state من الـ cloud
terraform refresh
```

---

## 10. التوقف المجدول (Planned Maintenance)

```bash
# 1. أبلغ المستخدمين (اختياري)

# 2. Scale down مؤقت (توفير تكاليف)
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --desired-count 0 \
  --region us-east-1

gcloud run services update sauda-backend \
  --min-instances 0 \
  --region us-central1

# 3. نفّذ الصيانة

# 4. أعد التشغيل
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --desired-count 2 \
  --region us-east-1

gcloud run services update sauda-backend \
  --min-instances 2 \
  --region us-central1
```
