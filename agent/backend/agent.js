const STEPS = [
  {
    key: 'name',
    question: "Let's start with the basics — what's your full name?",
    validate: (v) =>
      v.trim().length >= 2
        ? null
        : "Please enter your full name (at least 2 characters).",
  },
  {
    key: 'email',
    question: "Great! What's your email address?",
    validate: (v) =>
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim())
        ? null
        : "Hmm, that doesn't look right 🤔 Please enter a valid email (e.g. name@example.com).",
  },
  {
    key: 'phone',
    question: "And your phone number?",
    validate: (v) =>
      /^\+?[\d\s\-().]{7,}$/.test(v.trim())
        ? null
        : "Please enter a valid phone number (at least 7 digits, e.g. +966 50 123 4567).",
  },
  {
    key: 'location',
    question: "Where are you based? (city, country)",
    validate: (v) =>
      v.trim().length >= 2
        ? null
        : "Please enter your location (e.g. Riyadh, Saudi Arabia).",
  },
  {
    key: 'summary',
    question: 'Write a short professional summary about yourself.\n(or type "skip" to skip this section)',
    validate: (v) => {
      if (v.trim().toLowerCase() === 'skip') return null;
      return v.trim().split(/\s+/).length >= 5
        ? null
        : 'Please write at least 5 words, or type "skip".';
    },
  },
  {
    key: 'experience',
    question: 'Tell me about your work experience.\n(e.g. "Software Engineer at Acme, 2020–2023 – built APIs, led a team of 5")',
    validate: (v) =>
      v.trim().split(/\s+/).length >= 4
        ? null
        : "Please give a bit more detail (at least 4 words).",
  },
  {
    key: 'education',
    question: 'What is your highest level of education?\n(e.g. "BSc Computer Science, KAU, 2022")',
    validate: (v) =>
      v.trim().length >= 3
        ? null
        : "Please enter your education details (degree, institution, year).",
  },
  {
    key: 'skills',
    question: 'Almost done! List your top skills, separated by commas.\n(e.g. "JavaScript, Project Management, Communication")',
    validate: (v) =>
      v.trim().length >= 2 ? null : "Please enter at least one skill.",
  },
];

const INTRO =
  "Hala! 👋 I'm **Sauda**, your personal CV assistant.\n\nI'll ask you a few quick questions and craft a professional, ATS-ready CV just for you. It only takes a few minutes! 🚀";

function buildSummary(data) {
  const lines = [];
  if (data.name)       lines.push(`👤 **Name:** ${data.name}`);
  if (data.email)      lines.push(`📧 **Email:** ${data.email}`);
  if (data.phone)      lines.push(`📞 **Phone:** ${data.phone}`);
  if (data.location)   lines.push(`📍 **Location:** ${data.location}`);
  if (data.experience) lines.push(`🏢 **Experience:** ✓`);
  if (data.education)  lines.push(`🎓 **Education:** ✓`);
  if (data.skills)     lines.push(`⚡ **Skills:** ${data.skills.split(',').slice(0, 3).join(', ')}`);
  return lines.join('\n');
}

function initState() {
  return { step: 0, data: {}, confirmed: false };
}

function getNextQuestion(state) {
  if (state.step >= STEPS.length) {
    return (
      `All done! 🎉 Here's a summary of what I have:\n\n${buildSummary(state.data)}\n\n` +
      `Everything look good? Type **yes** to generate your CV — or **no** to start over.`
    );
  }
  return STEPS[state.step].question;
}

// Returns an error string if invalid, or null if the answer is acceptable.
function validateAnswer(state, answer) {
  const step = STEPS[state.step];
  if (!step || !step.validate) return null;
  return step.validate(answer);
}

// Advances state only after validation passes.
function updateState(state, answer) {
  const current = STEPS[state.step];
  if (current) {
    state.data[current.key] =
      answer.trim().toLowerCase() === 'skip' ? '' : answer.trim();
  }
  state.step++;
  return state;
}

function isAwaitingConfirmation(state) {
  return state.step >= STEPS.length && !state.confirmed;
}

function isComplete(state) {
  return state.step >= STEPS.length && state.confirmed === true;
}

function getProgress(state) {
  return { current: Math.min(state.step, STEPS.length), total: STEPS.length };
}

module.exports = {
  INTRO,
  initState,
  getNextQuestion,
  validateAnswer,
  updateState,
  isAwaitingConfirmation,
  isComplete,
  getProgress,
};
