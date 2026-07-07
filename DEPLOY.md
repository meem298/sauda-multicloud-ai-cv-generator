# DEPLOY.md — دليل النشر الكامل

> اتبع الأقسام **بالترتيب الصارم**. لا تتجاوز قسماً قبل إكمال السابق.

---

## القسم 1 — المتطلبات الأساسية

### الأدوات المطلوبة

```bash
# تحقق من الإصدارات
terraform version    # >= 1.6.0
aws --version        # >= 2.0.0
gcloud version       # >= 460.0.0
docker --version     # >= 24.0.0
node --version       # >= 20.0.0 (اختياري — للتطوير فقط)
```

**تثبيت Terraform:**
```bash
# macOS
brew tap hashicorp/tap && brew install hashicorp/tap/terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/
```

**تثبيت AWS CLI:**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

**تثبيت gcloud CLI:**
```bash
# macOS
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### الحسابات المطلوبة

**AWS:**
1. سجّل على [aws.amazon.com](https://aws.amazon.com) إذا لم يكن لديك حساب
2. فعّل **Billing Alerts:**
   - AWS Console → Billing → Billing Preferences → Receive Billing Alerts ✓
   - CloudWatch → Alarms → Create Alarm → Billing → Total Estimated Charge
   - ضع حداً عند $50 (dev) و $150 (prod)

**GCP:**
1. سجّل على [console.cloud.google.com](https://console.cloud.google.com)
2. أنشئ Project جديد: `sauda-production` (سجّل الـ Project ID)
3. اربط Billing Account بالـ Project
4. فعّل Budget Alert: GCP Console → Billing → Budgets & alerts → Create Budget

---

## القسم 2 — الإعداد الأولي (مرة واحدة فقط)

### 2a. إعداد AWS CLI

```bash
# أنشئ IAM User مخصص لـ Terraform (لا تستخدم root account)
# AWS Console → IAM → Users → Create User → اسمه: terraform-deployer

# أضف هذه الـ Policies:
# - AmazonVPC FullAccess
# - AmazonECS_FullAccess
# - AmazonEC2ContainerRegistryFullAccess
# - ElastiCacheFullAccess
# - AmazonS3FullAccess
# - CloudFrontFullAccess
# - AWSWAFv2FullAccess
# - AmazonRoute53FullAccess
# - SecretsManagerReadWrite
# - CloudWatchFullAccess
# - IAMFullAccess
# - AmazonDynamoDBFullAccess

# أنشئ Access Key للـ User وسجّل الـ Access Key ID + Secret

# أعدّ الـ CLI
aws configure
# AWS Access Key ID:     <ACCESS_KEY_ID>
# AWS Secret Access Key: <SECRET_ACCESS_KEY>
# Default region name:   us-east-1
# Default output format: json

# تحقق
aws sts get-caller-identity
```

### 2b. إعداد gcloud CLI

```bash
# سجّل دخولك
gcloud auth login
gcloud auth application-default login

# حدد المشروع
gcloud config set project <YOUR_GCP_PROJECT_ID>

# فعّل الـ APIs المطلوبة
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com \
  vpcaccess.googleapis.com \
  redis.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudarmor.googleapis.com \
  aiplatform.googleapis.com

# تحقق
gcloud projects describe <YOUR_GCP_PROJECT_ID>
```

### 2c. أنشئ GCP Service Account لـ Vertex AI

```bash
# أنشئ Service Account
gcloud iam service-accounts create sauda-vertex \
  --display-name="Sauda Vertex AI Service Account"

# امنحه صلاحية Vertex AI فقط
gcloud projects add-iam-policy-binding <YOUR_GCP_PROJECT_ID> \
  --member="serviceAccount:sauda-vertex@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# أنشئ وحمّل الـ JSON key
gcloud iam service-accounts keys create /tmp/vertex-sa-key.json \
  --iam-account=sauda-vertex@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com

# احتفظ بهذا الملف — ستحتاجه في القسم 4
# احذفه من /tmp بعد رفعه للـ Secrets Manager
```

---

## القسم 3 — Bootstrap: إنشاء State Backend (أول apply)

> هذه الخطوة **الأولى دائماً** — تنشئ S3 + DynamoDB لتخزين حالة Terraform.

```bash
cd infra/global/state-backend

# أنشئ ملف tfvars للـ bootstrap (لا يُحفظ في Git)
cat > terraform.tfvars <<EOF
state_bucket_name = "sauda-terraform-state-<YOUR_AWS_ACCOUNT_ID>"
lock_table_name   = "sauda-terraform-state-lock"
aws_region        = "us-east-1"
EOF

# شغّل — هذه المرة الوحيدة التي نستخدم local state
terraform init
terraform plan
terraform apply

# سجّل الـ outputs
terraform output
# state_bucket_name = "sauda-terraform-state-XXXXXXXXXXXX"
# lock_table_name   = "sauda-terraform-state-lock"

# احذف ملف tfvars بعد الانتهاء
rm terraform.tfvars
cd ../../..
```

---

## القسم 4 — تهيئة Backend لكل بيئة

```bash
# حدّث backend.tf في dev بالـ bucket الذي أنشأته
sed -i 's/<YOUR_STATE_BUCKET_NAME>/sauda-terraform-state-<YOUR_AWS_ACCOUNT_ID>/g' \
  infra/environments/dev/backend.tf

sed -i 's/<YOUR_STATE_BUCKET_NAME>/sauda-terraform-state-<YOUR_AWS_ACCOUNT_ID>/g' \
  infra/environments/prod/backend.tf

# أنشئ terraform.tfvars للـ dev (لا يُحفظ في Git — موجود في .gitignore)
cat > infra/environments/dev/terraform.tfvars <<EOF
gcp_project_id      = "<YOUR_GCP_PROJECT_ID>"
domain              = ""
acm_certificate_arn = "<ACM_CERTIFICATE_ARN>"
alert_email         = "<YOUR_EMAIL>"
image_tag           = "latest"
aws_region          = "us-east-1"
gcp_region          = "us-central1"
EOF
```

---

## القسم 5 — نشر Dev

### 5a. تطبيق Terraform Dev (أولاً — ينشئ ECR + ECS + ALB)

```bash
cd infra/environments/dev

terraform init
terraform plan -out=tfplan.dev
# راجع الـ plan — تأكد لا يوجد شيء غير متوقع

terraform apply tfplan.dev

# سجّل الـ outputs
terraform output
# ecr_repository_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/sauda/backend"
# alb_dns_name           = "sauda-alb-xxxx.us-east-1.elb.amazonaws.com"
# cloudfront_domain_name = "xxxx.cloudfront.net"

ECR_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS=$(terraform output -raw alb_dns_name)
CF_URL=$(terraform output -raw cloudfront_domain_name)

cd ../../..
```

### 5b. بناء ورفع Docker image (بعد terraform apply)

```bash
# ⚠️ لا تنفّذ هذا قبل 5a — الـ ECR repo يُنشأ بواسطة Terraform

# بناء الـ image
docker build -f docker/backend/Dockerfile -t sauda-backend:latest .

# تسجيل الدخول لـ ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# رفع الـ image
docker tag sauda-backend:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/sauda/backend:latest
docker push \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/sauda/backend:latest

# أجبر ECS على سحب الـ image الجديدة
aws ecs update-service \
  --cluster sauda-cluster \
  --service sauda-backend \
  --force-new-deployment \
  --region us-east-1

# انتظر حتى تكتمل الـ deployment
aws ecs wait services-stable \
  --cluster sauda-cluster \
  --services sauda-backend \
  --region us-east-1

echo "✓ ECS deployment complete"
```

> **ملاحظة GCP:** إذا فعّلت GCP stack، ارفع الـ image لـ Artifact Registry أيضاً:
> ```bash
> GCP_PROJECT_ID=<YOUR_GCP_PROJECT_ID>
> gcloud auth configure-docker us-central1-docker.pkg.dev
> docker tag sauda-backend:latest \
>   us-central1-docker.pkg.dev/${GCP_PROJECT_ID}/sauda-backend/backend:latest
> docker push \
>   us-central1-docker.pkg.dev/${GCP_PROJECT_ID}/sauda-backend/backend:latest
> ```

### 5c. رفع الأسرار

```bash
# رفع JWT Secret (نفس القيمة للمنصتين)
JWT_SECRET=$(openssl rand -base64 48)

# AWS
aws secretsmanager put-secret-value \
  --secret-id sauda/jwt-secret \
  --secret-string "${JWT_SECRET}" \
  --region us-east-1

# GCP
echo -n "${JWT_SECRET}" | gcloud secrets versions add sauda-jwt-secret --data-file=-

# رفع Vertex AI key
# AWS
aws secretsmanager put-secret-value \
  --secret-id sauda/vertex-ai-key \
  --secret-string "$(cat /tmp/vertex-sa-key.json)" \
  --region us-east-1

# GCP
gcloud secrets versions add sauda-vertex-ai-key \
  --data-file=/tmp/vertex-sa-key.json

# احذف الملف المحلي
rm /tmp/vertex-sa-key.json
```

### 5d. رفع الـ Frontend

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# AWS S3
aws s3 sync agent/frontend/ \
  s3://sauda-frontend-dev/ \
  --delete

# GCP Cloud Storage
gsutil rsync -r -d agent/frontend/ \
  gs://sauda-frontend-gcp-dev/
```

---

## القسم 6 — Smoke Tests بعد Dev

```bash
# احصل على الـ URLs من terraform output
ALB_DNS=$(cd infra/environments/dev && terraform output -raw alb_dns_name)
CF_URL=$(cd infra/environments/dev && terraform output -raw cloudfront_domain_name)

echo "==> Test 1: ALB Health Check (مباشر)"
curl -s "http://${ALB_DNS}/health" | grep '"status":"ok"'

echo "==> Test 2: CloudFront Health Check (عبر CDN)"
curl -s "https://${CF_URL}/health" | grep '"status":"ok"'

echo "==> Test 3: Frontend يُحمَّل"
curl -s -o /dev/null -w "%{http_code}" "https://${CF_URL}/" | grep "200"

echo "==> Test 4: API يستجيب"
curl -s -X POST "https://${CF_URL}/answer" \
  -H "Content-Type: application/json" \
  -d '{}' | grep "sessionId"

echo "==> All smoke tests passed ✓"
```

**افتح AWS Console وتحقق من:**
- ECS → Clusters → `sauda-cluster` → Services → `sauda-backend`: Running count = 1 ✓
- EC2 → Load Balancers → `sauda-alb` → Target Groups → Healthy = 1 ✓
- CloudWatch → Log Groups → `/sauda/backend-aws` → logs تظهر ✓
- CloudFront → Distribution → Status = Deployed ✓

---

## القسم 7 — نشر Prod (بعد تأكيد Dev)

```bash
# أنشئ terraform.tfvars للـ prod
cat > infra/environments/prod/terraform.tfvars <<EOF
gcp_project_id      = "<YOUR_GCP_PROJECT_ID>"
domain              = "<YOUR_DOMAIN>"
acm_certificate_arn = "<ACM_CERTIFICATE_ARN>"
alert_email         = "<YOUR_OPS_EMAIL>"
aws_region          = "us-east-1"
gcp_region          = "us-central1"
sns_alarm_arns      = []
EOF

cd infra/environments/prod

terraform init
terraform plan -out=tfplan.prod
# راجع بعناية — prod يكلّف أكثر

terraform apply tfplan.prod

cd ../../..

# رفع الأسرار لـ prod (نفس خطوات dev)
# رفع الـ images لـ prod
# رفع الـ frontend لـ prod (s3://sauda-frontend-prod/, gs://sauda-frontend-gcp-prod/)
```

**بعد نشر Prod:**
```bash
# تحقق من Route 53 يوزع الـ traffic
aws route53 get-health-check-status --health-check-id <AWS_HC_ID>
aws route53 get-health-check-status --health-check-id <GCP_HC_ID>
```

---

## القسم 8 — Teardown (إيقاف وحذف كل شيء)

> اتبع هذا الترتيب لتجنب orphan resources والتكاليف المستمرة.

```bash
# 1. أوقف prod أولاً
cd infra/environments/prod
terraform destroy
cd ../../..

# 2. أوقف dev
cd infra/environments/dev
terraform destroy
cd ../../..

# 3. احذف الـ images من ECR يدوياً (terraform لا يحذفها تلقائياً)
aws ecr batch-delete-image \
  --repository-name sauda/backend \
  --image-ids imageTag=latest \
  --region us-east-1

# 4. افرّغ S3 buckets قبل حذفها (Terraform لا يحذف bucket غير فارغ)
aws s3 rm s3://sauda-frontend-dev --recursive
aws s3 rm s3://sauda-pdfs-dev --recursive
aws s3 rm s3://sauda-frontend-prod --recursive
aws s3 rm s3://sauda-pdfs-prod --recursive

# 5. احذف State Backend أخيراً (بعد حذف كل شيء آخر)
aws s3 rm s3://sauda-terraform-state-<ACCOUNT_ID> --recursive
cd infra/global/state-backend
terraform init  # local state
terraform destroy
cd ../../..
```

---

## القسم 9 — استكشاف الأخطاء

### خطأ: `Error: No valid credential sources found`
```bash
# AWS
aws configure list  # تحقق من الـ credentials
aws sts get-caller-identity

# GCP
gcloud auth application-default login
```

### خطأ: `Error acquiring the state lock`
```bash
# تحقق من وجود lock قديم
aws dynamodb scan --table-name sauda-terraform-state-lock --region us-east-1

# احذف الـ lock يدوياً إذا كان stale
aws dynamodb delete-item \
  --table-name sauda-terraform-state-lock \
  --key '{"LockID": {"S": "sauda/dev/terraform.tfstate"}}' \
  --region us-east-1
```

### خطأ: `CannotPullContainerError` في ECS
```bash
# تحقق من أن الـ image موجودة في ECR
aws ecr list-images --repository-name sauda/backend --region us-east-1

# تحقق من VPC Endpoints
aws ec2 describe-vpc-endpoints --region us-east-1 | grep sauda
```

### خطأ: `PERMISSION_DENIED` في Cloud Run
```bash
# تحقق من Service Account permissions
gcloud projects get-iam-policy <PROJECT_ID> \
  --flatten="bindings[].members" \
  --filter="bindings.members:sauda-cloudrun"
```

### ECS Tasks تظهر Unhealthy
```bash
# افحص الـ logs
aws logs tail /sauda/backend-aws --follow --region us-east-1

# افحص health check مباشرة
ALB_DNS=$(cd infra/environments/dev && terraform output -raw aws_alb_dns)
curl -v "http://${ALB_DNS}/health"
```

### Cloud Run لا يرد
```bash
# افحص الـ logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50 --format=json

# افحص الـ service status
gcloud run services describe sauda-backend --region us-central1
```

### JWT Secret غير متطابق بين المنصتين
```bash
# تحقق من القيمة في AWS
aws secretsmanager get-secret-value \
  --secret-id sauda/jwt-secret \
  --query SecretString --output text

# تحقق من القيمة في GCP
gcloud secrets versions access latest --secret=sauda-jwt-secret

# إذا مختلفان — حدّث GCP ليطابق AWS
JWT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id sauda/jwt-secret \
  --query SecretString --output text)
echo -n "${JWT_SECRET}" | gcloud secrets versions add sauda-jwt-secret --data-file=-
```
