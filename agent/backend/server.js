const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const path = require('path');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const {
  INTRO,
  initState,
  getNextQuestion,
  validateAnswer,
  updateState,
  isAwaitingConfirmation,
  isComplete,
  getProgress,
} = require('./agent');
const { generateCV } = require('./cvGenerator');
const { generatePDF, generatePDFBuffer } = require('./pdfGenerator');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend')));

// ── DynamoDB sessions ──────────────────────────────────────────────────────
const SESSIONS_TABLE = process.env.SESSIONS_TABLE_NAME;
const SESSION_TTL_SEC = 24 * 60 * 60; // 24h — DynamoDB TTL auto-deletes

let docClient;
if (SESSIONS_TABLE) {
  const ddb = new DynamoDBClient({
    region: process.env.AWS_REGION_NAME || process.env.AWS_REGION || 'us-east-1',
  });
  docClient = DynamoDBDocumentClient.from(ddb);
}

// Fallback: in-memory Map for local development (no SESSIONS_TABLE env var).
const localSessions = new Map();

// ── S3 PDF storage ─────────────────────────────────────────────────────────
const PDF_BUCKET = process.env.PDF_BUCKET_NAME;
const PDF_PRESIGN_EXPIRES = 3600; // 1 hour

let s3Client;
if (PDF_BUCKET) {
  s3Client = new S3Client({
    region: process.env.AWS_REGION_NAME || process.env.AWS_REGION || 'us-east-1',
  });
}

async function uploadPDFToS3(data, sessionId) {
  const key = `cvs/${sessionId}.pdf`;
  const buffer = await generatePDFBuffer(data);
  await s3Client.send(new PutObjectCommand({
    Bucket: PDF_BUCKET,
    Key: key,
    Body: buffer,
    ContentType: 'application/pdf',
    ContentDisposition: 'attachment; filename="cv.pdf"',
  }));
  // Return presigned GET URL valid for 1 hour
  return getSignedUrl(s3Client, new GetObjectCommand({ Bucket: PDF_BUCKET, Key: key }), {
    expiresIn: PDF_PRESIGN_EXPIRES,
  });
}

async function getSession(id) {
  if (!docClient) return localSessions.get(id) ?? null;
  const result = await docClient.send(new GetCommand({
    TableName: SESSIONS_TABLE,
    Key: { session_id: id },
  }));
  return result.Item ? JSON.parse(result.Item.state) : null;
}

async function setSession(id, state) {
  if (!docClient) { localSessions.set(id, state); return; }
  await docClient.send(new PutCommand({
    TableName: SESSIONS_TABLE,
    Item: {
      session_id: id,
      state: JSON.stringify(state),
      expires_at: Math.floor(Date.now() / 1000) + SESSION_TTL_SEC,
    },
  }));
}

// ── Route handlers ─────────────────────────────────────────────────────────

const YES = new Set(['yes', 'y', 'yeah', 'yep', 'sure', 'ok', 'go', 'yup']);
const NO  = new Set(['no', 'n', 'nope', 'restart', 'start over', 'redo']);

app.post('/answer', async (req, res) => {
  const { sessionId, answer } = req.body;

  // ── New session ────────────────────────────────────────────────────────
  const existingState = sessionId ? await getSession(sessionId) : null;
  if (!sessionId || !existingState) {
    const id = sessionId || crypto.randomUUID();
    const state = initState();
    await setSession(id, state);
    return res.json({
      sessionId: id,
      intro: INTRO,
      question: getNextQuestion(state),
      done: false,
      progress: getProgress(state),
    });
  }

  const state = existingState;

  // ── Already complete (duplicate request) ──────────────────────────────
  if (isComplete(state)) {
    return res.json({
      sessionId,
      question: null,
      done: true,
      data: state.data,
      cv: generateCV(state.data),
      progress: getProgress(state),
    });
  }

  // ── Confirmation step ──────────────────────────────────────────────────
  if (isAwaitingConfirmation(state)) {
    const normalized = (answer ?? '').trim().toLowerCase();

    if (YES.has(normalized)) {
      state.confirmed = true;
      await setSession(sessionId, state);
      return res.json({
        sessionId,
        question: null,
        done: true,
        data: state.data,
        cv: generateCV(state.data),
        progress: getProgress(state),
      });
    }

    if (NO.has(normalized)) {
      const fresh = initState();
      await setSession(sessionId, fresh);
      return res.json({
        sessionId,
        intro: "No worries! Let's start over. 💪",
        question: getNextQuestion(fresh),
        done: false,
        progress: getProgress(fresh),
      });
    }

    return res.json({
      sessionId,
      question: "Just type **yes** to generate your CV, or **no** to start over 😊",
      done: false,
      progress: getProgress(state),
    });
  }

  // ── Validate answer ────────────────────────────────────────────────────
  const validationError = validateAnswer(state, answer ?? '');
  if (validationError) {
    return res.json({
      sessionId,
      question: validationError,
      done: false,
      progress: getProgress(state),
    });
  }

  // ── Advance state ──────────────────────────────────────────────────────
  updateState(state, answer ?? '');
  await setSession(sessionId, state);

  res.json({
    sessionId,
    question: getNextQuestion(state),
    done: false,
    progress: getProgress(state),
    confirming: isAwaitingConfirmation(state),
  });
});

app.get('/download-cv/:sessionId', async (req, res) => {
  const state = await getSession(req.params.sessionId);
  if (!state || !isComplete(state)) {
    return res.status(404).json({ error: 'Session not found or CV not ready' });
  }

  // S3 path: upload once, redirect browser to presigned URL.
  // Local dev path: stream directly to response.
  if (s3Client) {
    const url = await uploadPDFToS3(state.data, req.params.sessionId);
    return res.redirect(302, url);
  }

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', 'attachment; filename="cv.pdf"');
  generatePDF(state.data, res);
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

if (require.main === module) {
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`CV Agent running on port ${PORT}`);
  });
}

module.exports = app;
