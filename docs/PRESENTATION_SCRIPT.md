# سكربت العرض — Sauda AI CV Generator
## Multi-Cloud Architecture Presentation
**المدة:** 10–15 دقيقة | **الجمهور:** تقني (مهندسين / دكاترة)

---

> **كيف تستخدم هذا السكربت:**
> - كل قسم يبدأ بـ `[🖼️ انظر للديقرام:...]` لتعرف أين تشير
> - النص **الغامق** = مصطلحات تقنية إنجليزية تقولها كما هي
> - `[...]` = ملاحظات للمقدم فقط، لا تقرأها

---

## ═══════════════════════════════════════
## القسم 1: المقدمة (1 دقيقة)
## ═══════════════════════════════════════

بسم الله الرحمن الرحيم، السلام عليكم ورحمة الله وبركاته.

اليوم راح نشرح مشروع **Sauda AI CV Generator** — وهو تطبيق ويب يستخدم الذكاء الاصطناعي لتوليد السيرة الذاتية تلقائياً.

المستخدم يدخل بياناته، التطبيق يرسلها لنموذج الذكاء الاصطناعي، ويرجع له **CV** جاهز بصيغة **PDF**.

المشكلة اللي يحلها المشروع هي مشكلة **Availability** — لو عندك **Single Cloud Provider** وصار له **outage**، التطبيق يوقف. نحن حللنا هذا بتصميم **Active-Active Multi-Cloud Architecture** يشتغل على **AWS** و **GCP** في نفس الوقت.

---

## ═══════════════════════════════════════
## القسم 2: نظرة عامة على الـ Architecture (2 دقيقة)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: الصورة الكاملة — الجزء الأزرق (AWS) على اليسار والجزء الأخضر (GCP) على اليمين]

اللي تشوفونه في الديقرام هو **Active-Active Multi-Cloud Architecture**.

يعني التطبيق شغّال على **سحابتين** في **نفس الوقت**:

- **AWS** كـ **Primary Cloud** ويستقبل **60%** من الطلبات
- **GCP** كـ **Secondary Cloud** ويستقبل **40%** من الطلبات

ليش هذا التقسيم؟ لأن **AWS** عندها **ecosystem** أقوى وخبرة أكبر في الـ **enterprise workloads**، وأخذناها **Primary**. لكن **GCP** عندها **Vertex AI** — وهو الأرخص والأقوى لاستخدام **Gemini** — فاستخدمناها كـ **Secondary** وللـ **AI Layer**.

نقطة الدخول الوحيدة للمستخدم هي **Route 53** اللي يوزع الطلبات بين الـ **Cloud** تين.

---

## ═══════════════════════════════════════
## القسم 3: تتبع الـ Request (2 دقيقة)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: ابدأ من "Users" في الأعلى واتبع الأسهم]

خلونا نتبع رحلة الـ **Request** من لما المستخدم يضغط "Generate CV":

**1. DNS Resolution:**
المستخدم يفتح الموقع، الـ **DNS** يروح لـ **Route 53**. هنا **Route 53** يشوف — هل **AWS** شغّالة؟ هل **GCP** شغّالة؟ — ويوزع الطلب بناءً على الـ **Weighted Routing**.

**2. Edge Layer — الحماية الأولى:**
- لو وصل لـ **AWS**: يمر على **CloudFront** (الـ **CDN**) وبعدها **WAF** (الـ **Firewall**)
- لو وصل لـ **GCP**: يمر على **Cloud Armor** (الـ **WAF** بتاع **GCP**)

هنا يُفحص الـ **Request** — هل فيه **SQL Injection**؟ هل فيه **XSS Attack**؟ لو فيه، يُحذف فوراً.

**3. Load Balancing:**
الـ **Request** الآمن يكمل لـ **Application Load Balancer** في **AWS** أو **Global Load Balancer** في **GCP**.

**4. Compute:**
الـ **Backend** يشتغل على:
- **ECS Fargate** في **AWS** (يشغّل **Node.js** container)
- **Cloud Run** في **GCP** (نفس الـ **Docker image**)

**5. AI Processing:**
الـ **Backend** يرسل النص لـ **Vertex AI** — **Gemini 1.5 Flash** — اللي يعالج البيانات ويرجع **CV** محسّن.

**6. Storage & Response:**
الـ **PDF** يتخزن في **S3** أو **Cloud Storage**، والمستخدم يحصل على **Download Link**.

---

## ═══════════════════════════════════════
## القسم 4: AWS Services — الشرح التفصيلي (3 دقائق)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: الجزء الأزرق الكبير على اليسار]

### نقطة الدخول:

**Route 53** — خدمة الـ **DNS** بتاعة **AWS**.
مش مجرد **DNS** عادي — عنده **Health Checks** كل **10 ثواني**. لو **AWS** انقطعت، خلال **60 ثانية** كل الطلبات تتحول لـ **GCP** تلقائياً. هذا هو الـ **Failover** اللي يضمن الـ **High Availability**.

---

### Edge Layer — طبقة الحافة:

**CloudFront** — الـ **CDN** بتاع **AWS**.
يحتفظ بنسخة من الـ **Static Assets** (الـ **HTML**، الـ **CSS**، الـ **JavaScript**) في أكثر من **200 Edge Location** حول العالم. يعني المستخدم في السعودية يحمّل الموقع من أقرب **server** جغرافياً، مش من **US East**.

**WAF v2 (Web Application Firewall)** — درع الحماية.
يطبّق **AWSManagedRulesCommonRuleSet** — قواعد جاهزة من **AWS** تحمي من **SQL Injection** و **XSS**. عنده أيضاً **Rate Limiting**: 1000 **request** في الثانية كحد أقصى لكل **IP**.

**ACM (AWS Certificate Manager)** — إدارة شهادات الـ **SSL/TLS**.
يجدد الشهادات تلقائياً، مجاناً. يضمن إن كل الاتصالات **Encrypted** بـ **HTTPS**.

---

### Networking — الشبكة:

[🖼️ انظر للديقرام: المربع الداخلي VPC 10.0.0.0/16]

**VPC (Virtual Private Cloud)** — شبكة خاصة معزولة بالكامل.
صمّمناها بـ **4 Subnets** على **Availability Zones** مختلفة:
- **2 Public Subnets** — فيها الـ **ALB** والـ **NAT Gateway** (تتواصل مع الإنترنت)
- **2 Private Subnets** — فيها الـ **ECS Fargate** (معزولة تماماً، لا يصلها الإنترنت مباشرة)

**NAT Gateway** — يسمح للـ **ECS Fargate** في الـ **Private Subnets** إنه يتواصل مع الإنترنت للخارج (مثلاً لتحديث **packages**) لكن الإنترنت ما يقدر يوصله مباشرة. الـ **Security** هنا في الاتجاه الواحد.

**ALB (Application Load Balancer)** — الـ **Load Balancer** من **Layer 7**.
يوزع الطلبات على **ECS Tasks** في الـ **AZs** المختلفة. لو **Task** واحد راح، الثاني يستحمل الحمل. يعمل أيضاً **Health Checks** على الـ **Containers**.

---

### Compute — الحوسبة:

**ECS Fargate** — تشغيل **Containers** بدون إدارة **Servers**.
البـ **Backend** بتاعنا هو **Node.js 20** مع **Express.js** يشتغل داخل **Docker Container**. **Fargate** يدير كل حاجة تانية: الـ **scaling**، الـ **patching**، الـ **infrastructure**.

الـ **Specs** في **Dev**: 0.25 **vCPU** / 512 **MB RAM**.
الـ **Specs** في **Prod**: 0.5 **vCPU** / 1 **GB RAM**، مع **Auto Scaling** من 1 لـ 10 **Tasks**.

**ECR (Elastic Container Registry)** — المستودع الخاص بالـ **Docker Images**.
كل مرة نبني **Image** جديد، يتحمّل هنا. **ECS Fargate** يسحبه منه مباشرة. فيه **Scan on Push** — يفحص الـ **Image** تلقائياً عن **Vulnerabilities**.

---

### Data Layer — طبقة البيانات:

**DynamoDB** — قاعدة بيانات **NoSQL** من **AWS**.
نستخدمها لتخزين الـ **JWT Blacklist** (التوكنات المُلغاة بعد الـ **Logout**). اخترنا **Pay-Per-Request Billing** — ما ندفع إلا لما فيه طلبات فعلية. يدعم **TTL (Time-to-Live)** لحذف السجلات القديمة تلقائياً.

**S3 (Simple Storage Service)** — تخزين الملفات.
**Bucket** أول للـ **Frontend Static Assets**، و**Bucket** ثاني لملفات الـ **PDF** المولّدة. الـ **PDFs** عندها **Lifecycle Policy** تحذفها بعد **7 أيام** لتوفير التكلفة.

**Secrets Manager** — خزنة الأسرار.
فيها الـ **JWT Signing Secret** ومفتاح الـ **Vertex AI Service Account**. **لا يوجد** أي **Secret** مكتوب في الكود. كل **Secret** يُقرأ بـ **API Call** وقت التشغيل فقط. يكلف **$0.80/شهر** — ثمن بخس مقابل الأمان.

**CloudWatch** — المراقبة والـ **Logging**.
يجمع كل الـ **Logs** من **ECS** في **Log Group** اسمه `/sauda/backend-aws`. عنده **Alarms** تنبهنا لو:
- الـ **CPU** تجاوز **70%**
- الـ **Memory** تجاوز **80%**
- الـ **5xx Errors** ارتفعت
- الـ **Response Time** تجاوز **3 ثواني**

---

## ═══════════════════════════════════════
## القسم 5: GCP Services — الشرح التفصيلي (2 دقيقتان)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: الجزء الأخضر الكبير على اليمين]

### Edge Layer:

**Cloud Armor** — الـ **WAF** بتاع **GCP**.
يطبّق نفس مبدأ الـ **WAF** في **AWS**: قواعد **OWASP** جاهزة، **Rate Limiting** (1000 **request** كل **5 دقائق** لكل **IP**)، وحماية من **DDoS**.

**Global Load Balancer** — الـ **Load Balancer** الـ **Global** بتاع **GCP**.
يختار أقرب **Region** للمستخدم تلقائياً. يدعم **HTTPS Termination** ويوزع الطلبات على **Cloud Run**.

---

### Compute:

**Cloud Run** — نظير **ECS Fargate** في **GCP**.
يشغّل **نفس** الـ **Docker Image** اللي شغّال على **ECS**. مزيّته إنه **Serverless تماماً** — يبدأ من **0 instances** لما ما فيه طلبات، ويـ **scale** لـ **20 instance** لما يزيد الضغط. في **Dev** يكون **min: 0** يعني تكلفته **$0** لما ما فيه استخدام.

**Artifact Registry** — نظير **ECR** في **GCP**.
يخزن الـ **Docker Image** في `us-central1-docker.pkg.dev`. عنده **500 MB** مجاناً في الـ **Always Free Tier**.

---

### Data Layer:

**Cloud Storage (GCS)** — نظير **S3** في **GCP**.
نفس الهيكل: **Bucket** للـ **Frontend** و**Bucket** للـ **PDFs** بـ **7-day Lifecycle**. يدعم **Signed URLs** لتحميل الملفات مؤقتاً بأمان.

**Firestore** — قاعدة بيانات **NoSQL** في **GCP**.
نفس دور **DynamoDB** — تخزين الـ **JWT Blacklist**. اخترناه لأنه في الـ **Always Free Tier**: **1 GB تخزين** و**50,000 Read** يومياً مجاناً. يدعم **TTL** للحذف التلقائي.

**Secret Manager** — نظير **Secrets Manager** في **AWS**.
يخزن نفس الـ **Secrets** (الـ **JWT Secret** ومفتاح **Vertex AI**) بـ **Auto Replication**. يكلف **$0.12/شهر**.

**Cloud Monitoring** — نظير **CloudWatch** في **GCP**.
يراقب **Cloud Run**: **Uptime Checks** كل **10 ثواني** على **endpoint** `/health`، و**Alerts** لو **CPU** تجاوز **70%** أو **5xx Errors** تجاوزت **1%**.

---

## ═══════════════════════════════════════
## القسم 6: الـ AI Layer — قلب المشروع (1 دقيقة)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: المربع البنفسجي في الأسفل — Vertex AI]

**Vertex AI** مع **Gemini 1.5 Flash** هو الـ **AI Model** اللي يولّد السيرة الذاتية.

**كيف يشتغل؟**
كلا الـ **Backends** — **ECS Fargate** و**Cloud Run** — يرسلون الـ **Request** لنفس الـ **Vertex AI Endpoint** في **GCP**. يستخدمون **Service Account** مشترك بصلاحيات محدودة للوصول.

**ليش Vertex AI وليس AWS Bedrock؟**
- **Gemini 1.5 Flash**: $0.075 لكل مليون **Token input** و$0.30 لكل مليون **Token output**
- **AWS Bedrock Haiku**: أغلى بنسبة ~40%
- هذا هو المبرر الرئيسي لاستخدام **GCP** في هذا المشروع

**التكلفة:** بمعدل 100 **CV** يومياً، الـ **AI** تكلفته **$1-5/شهر** فقط.

---

## ═══════════════════════════════════════
## القسم 7: الأمان — Security (1 دقيقة)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: الـ WAF على AWS والـ Cloud Armor على GCP]

صمّمنا الأمان على **4 طبقات**:

**الطبقة الأولى — Edge Security:**
**WAF** + **Cloud Armor** يحميان من **SQL Injection** و**XSS** و**DDoS** قبل ما الـ **Request** يصل للـ **Backend** خالص.

**الطبقة الثانية — Network Security:**
الـ **Backend** في **Private Subnets** — لا يمكن الوصول إليه مباشرة من الإنترنت. الـ **Security Groups** مضبوطة بـ **Least Privilege**: الـ **ALB** يقبل الـ **80/443** من الإنترنت فقط، والـ **ECS** يقبل الـ **3000** من الـ **ALB** فقط.

**الطبقة الثالثة — Secrets Management:**
**لا يوجد** أي **Secret** أو **Password** مكتوب في الكود أو في الـ **Git**. كل شيء في **Secrets Manager** + **Secret Manager**.

**الطبقة الرابعة — Authentication:**
نستخدم **JWT Stateless Sessions** — الـ **Token** يتحقق منه أي **Backend** (سواء **AWS** أو **GCP**) بدون حاجة لمشاركة **Session State** بينهم. اللي يعمل **Logout** يتضاف توكنه للـ **Blacklist** في **DynamoDB** أو **Firestore**.

---

## ═══════════════════════════════════════
## القسم 8: المراقبة والـ Observability (30 ثانية)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: CloudWatch على يمين AWS، وCloud Monitoring على يمين GCP]

كل **Cloud** عندها **Monitoring** مستقل:
- **AWS**: **CloudWatch** يجمع الـ **Logs** والـ **Metrics** ويطلق **Alarms**
- **GCP**: **Cloud Monitoring** يراقب **Cloud Run** بـ **Uptime Checks**

الـ **Health Checks** كل **10 ثواني**. لو **3 فحوصات** متتالية فشلت — **Route 53** يُخرج الـ **Cloud** اللي واقفة من الـ **DNS** خلال **60 ثانية**. هذا هو الـ **RTO** بتاعنا: أقل من دقيقة.

---

## ═══════════════════════════════════════
## القسم 9: الـ DevOps والـ Infrastructure as Code (1 دقيقة)
## ═══════════════════════════════════════

[🖼️ انظر للديقرام: الصف السفلي — Terraform, GitHub Actions, Docker]

**Terraform — Infrastructure as Code:**
كل الـ **Infrastructure** اللي شرحناها — الـ **VPCs**، الـ **ECS**، الـ **Cloud Run**، الـ **WAF**، كل شيء — مكتوب كـ **Code** في **Terraform**. فوائده:
- **Reproducible**: تقدر تعمل نفس البيئة في أي **Region** بأمر واحد
- **Version Controlled**: كل تغيير يتتبع في **Git**
- **Modular**: عندنا **17 Module** مستقل، كل واحد مسؤول عن جزء

الـ **State** يتخزن في **S3 + DynamoDB** لمنع الـ **Concurrent Applies** (الـ **DynamoDB** يعمل كـ **Lock**).

**Docker:**
عندنا **Dockerfile** واحد للـ **Backend**. نفس الـ **Image** يتحمّل على **ECR** (الـ **AWS Registry**) وعلى **Artifact Registry** (الـ **GCP Registry**). مزيّة: نبني مرة، ونشغّل في مكانين.

**GitHub Actions:**
الـ **CI Pipeline** يشغّل `terraform fmt` و`tflint` و`hadolint` على كل **Pull Request**. لا يوجد **Auto Apply** — الـ **Deployment** يدوي عن قصد، لأننا ما نريد تغييرات **Infrastructure** تنزل تلقائياً بدون مراجعة.

---

## ═══════════════════════════════════════
## القسم 10: التكلفة والخلاصة (30 ثانية)
## ═══════════════════════════════════════

**التكلفة الشهرية المقدّرة:**

| البيئة | التكلفة |
|--------|---------|
| **Dev** | ~$71/شهر |
| **Prod** | ~$120/شهر |

الخدمات اللي في الـ **Always Free Tier** (تكلفتها صفر):
- **DynamoDB** (25 GB + 25 WCU/RCU)
- **Cloud Run** (2 مليون طلب/شهر)
- **S3** (5 GB)
- **Firestore** (1 GB + 50K reads يومياً)
- **CloudFront** (1 TB/شهر)

**الخلاصة:**

صمّمنا **Production-Grade Infrastructure** يحقق **4 مبادئ**:
1. **High Availability** — لا يوجد **Single Point of Failure**
2. **Security** — **4 طبقات حماية** ولا **Secret** في الكود
3. **Observability** — كل شيء يتراقب ويُنبه عنه
4. **Auto Scaling** — يكبر مع الطلب تلقائياً

وكل الـ **Infrastructure** مكتوب كـ **Code** جاهز للـ **Deploy** بأوامر **Terraform** بسيطة.

شكراً لكم. أنا جاهز للأسئلة.

---

## ═══════════════════════════════════════
## ملاحظات إضافية للمقدم (لا تُقرأ)
## ═══════════════════════════════════════

### أسئلة متوقعة وإجاباتها:

**س: ليش ما استخدمتم Kubernetes؟**
ج: ECS Fargate و Cloud Run يعطوننا نفس الـ Auto Scaling بدون تعقيدات الـ Control Plane. EKS يكلف $73/شهر للـ Control Plane وحده. للـ Workload بتاعنا (Stateless Web App)، Fargate + Cloud Run هو الاختيار الصح.

**س: ليش AWS Primary وليس GCP؟**
ج: AWS عندها Ecosystem أوسع، Documentation أفضل، وServices أكثر نضجاً في الـ Enterprise. GCP نستخدمها لـ Vertex AI فقط — وهذا أرخص 40% من AWS Bedrock.

**س: كيف تضمنون Consistency بين الـ Two Clouds؟**
ج: الـ Sessions عندنا Stateless (JWT). ما فيه Data يحتاج Sync. الـ JWT Blacklist مستقل في كل Cloud. الـ PDFs تتخزن في Cloud اللي ولّدها وتُحذف بعد 7 أيام. ما عندنا Cross-Cloud Replication.

**س: ما هو أكبر تحدي واجهتموه؟**
ج: تصميم الـ Stateless JWT Architecture بحيث أي Backend يقدر يُحقق من أي Token بدون مشاركة State. هذا حل مشكلة الـ Session Synchronization بين Cloud ين مختلفين.

**س: ما هو الـ RTO و RPO؟**
ج: RPO = 0 (لأن الـ Sessions Stateless، ما في Data يضيع). RTO < 60 ثانية (Route 53 يحتاج 3 Health Check Failures × 10 ثواني + TTL 30 ثانية).
