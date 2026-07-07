let sessionId = null;

// ── Markdown: escape HTML then apply **bold** and \n → <br> ─────────────
function md(text) {
  return text
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\n/g, '<br>');
}

// ── Append a message bubble ──────────────────────────────────────────────
function addMessage(text, sender) {
  const msgs = document.getElementById('messages');
  removeTyping();

  const row = document.createElement('div');
  row.className = `msg-row ${sender}`;

  if (sender === 'agent') {
    const av = document.createElement('div');
    av.className = 'msg-avatar';
    av.textContent = '👩‍💼';
    row.appendChild(av);
  }

  const bubble = document.createElement('div');
  bubble.className = `msg ${sender}`;
  // Agent messages support **bold** and line breaks; user messages are plain text.
  if (sender === 'agent') {
    bubble.innerHTML = md(text);
  } else {
    bubble.textContent = text;
  }
  row.appendChild(bubble);

  msgs.appendChild(row);
  msgs.scrollTop = msgs.scrollHeight;
}

// ── Typing indicator ─────────────────────────────────────────────────────
function showTyping() {
  const msgs = document.getElementById('messages');
  if (document.getElementById('typing')) return;
  const row = document.createElement('div');
  row.id = 'typing';
  row.className = 'typing-row';
  row.innerHTML = `
    <div class="msg-avatar">👩‍💼</div>
    <div class="typing-bubble"><span></span><span></span><span></span></div>
  `;
  msgs.appendChild(row);
  msgs.scrollTop = msgs.scrollHeight;
}
function removeTyping() {
  const t = document.getElementById('typing');
  if (t) t.remove();
}

// ── Progress bar ─────────────────────────────────────────────────────────
const STEP_LABELS = ['Starting up…','Name','Email','Phone','Location','Summary','Experience','Education','Skills'];
function updateProgress(current, total) {
  const pct = Math.round((current / total) * 100);
  document.getElementById('progress-fill').style.width = `${pct}%`;
  document.getElementById('progress-count').textContent = `${current} / ${total}`;
  document.getElementById('progress-label').textContent =
    current === 0 ? 'Starting up…' :
    current < STEP_LABELS.length ? `Step ${current}: ${STEP_LABELS[current]}` :
    '🎉 Almost done!';
}

// ── Show CV output card ───────────────────────────────────────────────────
function showCV(cvText) {
  const card = document.getElementById('cv-output');
  document.getElementById('cv-text').value = cvText;
  card.style.display = 'block';
  card.scrollIntoView({ behavior: 'smooth', block: 'start' });
  document.getElementById('download-btn').onclick = () => {
    window.location.href = `/download-cv/${sessionId}`;
  };
}

// ── Core send function ───────────────────────────────────────────────────
async function sendAnswer(answer) {
  const btn   = document.getElementById('send-btn');
  const input = document.getElementById('user-input');
  btn.disabled = true;
  showTyping();

  // Small pause so the typing indicator feels natural
  await new Promise(r => setTimeout(r, 650));

  try {
    const res  = await fetch('/answer', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sessionId, answer }),
    });
    const data = await res.json();
    sessionId  = data.sessionId;

    removeTyping();

    // Intro message (new session or restart)
    if (data.intro) {
      addMessage(data.intro, 'agent');
      await new Promise(r => setTimeout(r, 400));
    }

    if (data.progress) {
      updateProgress(data.progress.current, data.progress.total);
    }

    if (data.done) {
      updateProgress(8, 8);
      addMessage("Here's your CV below! Feel free to edit it, then hit Download PDF. 🎉", 'agent');
      showCV(data.cv);
      input.disabled = true;
      // btn stays disabled — conversation is over
    } else {
      addMessage(data.question, 'agent');
      btn.disabled = false;
      input.focus();
    }

  } catch {
    removeTyping();
    addMessage("Something went wrong — please refresh and try again.", 'agent');
    btn.disabled = false;
  }
}

// ── Event listeners ──────────────────────────────────────────────────────
document.getElementById('send-btn').addEventListener('click', () => {
  const input = document.getElementById('user-input');
  const val   = input.value.trim();
  if (!val && sessionId) return;
  if (sessionId) addMessage(val, 'user');
  input.value = '';
  sendAnswer(val);
});

document.getElementById('user-input').addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    document.getElementById('send-btn').click();
  }
});

// Kick off the conversation on page load
sendAnswer('');
