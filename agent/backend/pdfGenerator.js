 const PDFDocument = require('pdfkit');
const { parseExperience } = require('./cvGenerator');

const MARGIN = 50;
const HEADING_COLOR = '#1a1a1a';
const MUTED_COLOR = '#6c757d';
const ACCENT_COLOR = '#2563eb';

function sectionHeading(doc, title) {
  doc.moveDown(0.8)
    .fontSize(11).font('Helvetica-Bold').fillColor(ACCENT_COLOR)
    .text(title.toUpperCase())
    .moveDown(0.15)
    .moveTo(MARGIN, doc.y)
    .lineTo(doc.page.width - MARGIN, doc.y)
    .strokeColor('#dee2e6').lineWidth(0.5).stroke()
    .moveDown(0.3);
}

// Collects PDF bytes into a Buffer — used when uploading to S3.
function generatePDFBuffer(data) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: MARGIN, size: 'A4' });
    const chunks = [];
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    _buildPDF(doc, data);
  });
}

function generatePDF(data, res) {
  const doc = new PDFDocument({ margin: MARGIN, size: 'A4' });
  doc.pipe(res);
  _buildPDF(doc, data);
}

function _buildPDF(doc, data) {

  // Name
  doc.fontSize(22).font('Helvetica-Bold').fillColor(HEADING_COLOR)
    .text(data.name.toUpperCase(), { align: 'center' });

  // Contact line
  const contact = [data.email, data.phone, data.location].filter(Boolean).join('   |   ');
  if (contact) {
    doc.moveDown(0.3)
      .fontSize(9).font('Helvetica').fillColor(MUTED_COLOR)
      .text(contact, { align: 'center' });
  }

  // Summary
  if (data.summary) {
    sectionHeading(doc, 'Professional Summary');
    doc.fontSize(10).font('Helvetica').fillColor(HEADING_COLOR)
      .text(data.summary, { lineGap: 2 });
  }

  // Experience
  if (data.experience) {
    sectionHeading(doc, 'Work Experience');
    const { header, bullets } = parseExperience(data.experience);
    doc.fontSize(10).font('Helvetica-Bold').fillColor(HEADING_COLOR).text(header);
    doc.font('Helvetica').fillColor(HEADING_COLOR);
    bullets.forEach(b => {
      doc.text(`•  ${b}`, { indent: 12, lineGap: 2 });
    });
  }

  // Education
  if (data.education) {
    sectionHeading(doc, 'Education');
    doc.fontSize(10).font('Helvetica').fillColor(HEADING_COLOR)
      .text(data.education, { lineGap: 2 });
  }

  // Skills
  if (data.skills) {
    sectionHeading(doc, 'Skills');
    const skills = data.skills.split(',').map(s => s.trim()).filter(Boolean);
    doc.fontSize(10).font('Helvetica').fillColor(HEADING_COLOR)
      .text(skills.join('   •   '), { lineGap: 2 });
  }

  doc.end();
}

module.exports = { generatePDF, generatePDFBuffer };
