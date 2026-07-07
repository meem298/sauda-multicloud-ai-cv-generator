# Project Roadmap: AI CV Generator Agent

---

## Phase 1: Local Agent + Backend ✅ (mostly done)

### Task 1 — Express Server Bootstrap ✅
- [x] Set up Express with JSON body parsing and CORS
- [x] POST `/answer` endpoint
- [x] Static file serving for frontend
- [x] Start server on port 3000

### Task 2 — Agent State Machine ✅
- [x] Define CV sections: name, email, phone, location, summary, experience, education, skills
- [x] `initState()` / `getNextQuestion()` / `updateState()` / `isComplete()`

### Task 3 — Session Store ✅
- [x] In-memory `Map<sessionId, state>`
- [x] Return `{ sessionId, question, done }` from `/answer`

### Task 4 — Answer Validation ⬜
- [ ] Reject empty or too-short answers with a follow-up prompt
- [ ] Validate email format
- [ ] Validate phone format (basic)
- [ ] Re-ask if answer does not match expected format

---

## Phase 2: Frontend UI ✅ (done)

### Task 5 — Chat UI ✅
- [x] Message list with agent/user bubbles
- [x] Text input + Send button, Enter key support
- [x] Auto-scroll to latest message
- [x] Loading / disabled state while waiting

### Task 6 — UI Polish ⬜
- [ ] Show typing indicator (animated dots) while agent "thinks"
- [ ] Mobile-responsive layout
- [ ] Progress bar or step counter (e.g. "Step 3 of 8")

---

## Phase 3: CV Generation ✅ (done)

### Task 7 — ATS-Friendly Text CV ✅
- [x] `backend/cvGenerator.js` — `generateCV(data)`
- [x] Sections: Summary, Work Experience (with bullets), Education, Skills
- [x] Editable textarea in frontend

### Task 8 — CV Quality Improvements ⬜
- [ ] Add action verbs to experience bullets automatically
- [ ] Warn user if summary is too short (< 20 words)
- [ ] Support multiple experience entries
- [ ] Support multiple education entries

---

## Phase 4: PDF Export ✅ (done)

### Task 9 — PDF Generation ✅
- [x] `backend/pdfGenerator.js` — PDFKit, styled A4 PDF
- [x] `GET /download-cv/:sessionId` endpoint
- [x] "Download PDF" button in frontend

### Task 10 — PDF Quality ⬜
- [ ] Improve font sizing and spacing
- [ ] Add header color / accent line
- [ ] Ensure no content overflow onto second page
- [ ] Test with long content (wrapping)

---

## Phase 5: Cloud Deploy (AWS) ⬜

### Task 11 — Prepare for Production
- [ ] Move in-memory sessions to Redis (AWS ElastiCache or Upstash)
- [ ] Add `.env` for config (PORT, REDIS_URL, etc.)
- [ ] Add basic rate limiting (express-rate-limit)
- [ ] Add input sanitization

### Task 12 — Containerize
- [ ] Write `Dockerfile` for the Node.js backend
- [ ] Write `docker-compose.yml` for local testing with Redis
- [ ] Test container build locally

### Task 13 — AWS Infrastructure (low-cost)
- [ ] Deploy container to AWS App Runner (simplest, auto-scaling, pay-per-use)
- [ ] Or: EC2 t3.micro + nginx (cheapest fixed cost ~$10/mo)
- [ ] Store PDFs temporarily in S3 (generate pre-signed download URL)
- [ ] Use Route 53 for custom domain (optional)

### Task 14 — CI/CD
- [ ] GitHub Actions: on push to main → build Docker image → deploy to AWS
- [ ] Add health check endpoint `GET /health`

---

## Current Status
| Phase | Status |
|-------|--------|
| Phase 1: Agent + Backend | ✅ Done (validation pending) |
| Phase 2: Frontend UI | ✅ Done (polish pending) |
| Phase 3: CV Generation | ✅ Done (multi-entry pending) |
| Phase 4: PDF Export | ✅ Done (quality polish pending) |
| Phase 5: Cloud Deploy | ⬜ Not started |

## Next Up
**Task 4 — Answer Validation** (complete Phase 1 properly before moving to cloud)
