// Parses "Role at Company, 2020-2023 – did X, improved Y" into header + bullets.
function parseExperience(text) {
  const [header, ...rest] = text.split(/\s[–-]\s/);
  const bullets = rest.length
    ? rest.join(' – ').split(',').map(b => b.trim()).filter(Boolean)
    : [];
  return { header: header.trim(), bullets };
}

function generateCV(data) {
  const lines = [];

  // Header
  lines.push(data.name.toUpperCase());
  const contact = [data.email, data.phone, data.location].filter(Boolean).join(' | ');
  if (contact) lines.push(contact);

  // Summary
  if (data.summary) {
    lines.push('');
    lines.push('PROFESSIONAL SUMMARY');
    lines.push(data.summary);
  }

  // Experience
  if (data.experience) {
    lines.push('');
    lines.push('WORK EXPERIENCE');
    const { header, bullets } = parseExperience(data.experience);
    lines.push(header);
    bullets.forEach(b => lines.push(`  * ${b}`));
  }

  // Education
  if (data.education) {
    lines.push('');
    lines.push('EDUCATION');
    lines.push(data.education);
  }

  // Skills
  if (data.skills) {
    lines.push('');
    lines.push('SKILLS');
    const skills = data.skills.split(',').map(s => s.trim()).filter(Boolean);
    lines.push(skills.join(' | '));
  }

  return lines.join('\n');
}

module.exports = { generateCV, parseExperience };
