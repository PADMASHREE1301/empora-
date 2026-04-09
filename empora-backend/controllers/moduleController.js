// empora-backend/controllers/moduleController.js
//
// Generic controller used by ALL module routes.
// Each route file passes its Mongoose Model in, so this one controller
// handles stratic, taxation, landLegal, licence, loans,
// riskManagement, projectManagement, cyberSecurity, restructure.

const path = require('path');
const fs   = require('fs');

// ─── Text extraction (shared) ─────────────────────────────────────────────────
async function extractTextFromFile(filePath, originalName) {
  const ext = path.extname(originalName || '').toLowerCase();
  try {
    if (ext === '.pdf') {
      const pdfParse = require('pdf-parse');
      const buffer   = fs.readFileSync(filePath);
      const data     = await pdfParse(buffer);
      return (data.text || '').trim().slice(0, 12000);
    }
    if (ext === '.doc' || ext === '.docx') {
      const mammoth = require('mammoth');
      const result  = await mammoth.extractRawText({ path: filePath });
      return (result.value || '').trim().slice(0, 12000);
    }
    if (ext === '.xls' || ext === '.xlsx') {
      const XLSX     = require('xlsx');
      const workbook = XLSX.readFile(filePath);
      let text = '';
      workbook.SheetNames.forEach((name) => {
        text += `\n--- Sheet: ${name} ---\n`;
        text += XLSX.utils.sheet_to_csv(workbook.Sheets[name]);
      });
      return text.trim().slice(0, 12000);
    }
    if (ext === '.ppt' || ext === '.pptx') {
      try {
        const AdmZip  = require('adm-zip');
        const zip     = new AdmZip(filePath);
        const entries = zip.getEntries().filter(
          (e) => e.entryName.startsWith('ppt/slides/slide') && e.entryName.endsWith('.xml')
        );
        let text = '';
        entries.forEach((entry) => {
          const xml = entry.getData().toString('utf8');
          text += xml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ') + '\n';
        });
        return text.trim().slice(0, 12000);
      } catch (_) {
        return `[Could not extract text from ${originalName}]`;
      }
    }
    if (ext === '.txt' || ext === '.csv') {
      return fs.readFileSync(filePath, 'utf8').trim().slice(0, 12000);
    }
    return '';
  } catch (err) {
    console.error(`Text extraction failed for ${originalName}:`, err.message);
    return `[Extraction error: ${err.message}]`;
  }
}

function _deleteOldFile(fileUrl) {
  if (!fileUrl) return;
  try {
    const fullPath = path.join(__dirname, '..', fileUrl);
    if (fs.existsSync(fullPath)) fs.unlinkSync(fullPath);
  } catch (_) {}
}

async function _ownedRecord(Model, recordId, userId) {
  const record = await Model.findById(recordId);
  if (!record) return null;
  if (record.owner.toString() !== userId) return null;
  return record;
}

function _notFound(res) {
  return res.status(404).json({ success: false, message: 'Record not found or access denied.' });
}

// ─── Factory: returns a controller object bound to a specific Model ───────────
function createModuleController(Model) {

  // POST /api/:module/create
  const createRecord = async (req, res) => {
    try {
      const record = await Model.create({ owner: req.user.id, status: 'draft' });
      return res.status(201).json({ success: true, message: 'Record created.', data: record });
    } catch (err) {
      console.error('createRecord error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // GET /api/:module/my
  const getMyRecords = async (req, res) => {
    try {
      const records = await Model.find({ owner: req.user.id })
        .sort({ updatedAt: -1 })
        .select('-__v');
      return res.status(200).json({ success: true, count: records.length, data: records });
    } catch (err) {
      console.error('getMyRecords error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // GET /api/:module/:id
  const getRecordById = async (req, res) => {
    try {
      const record = await Model.findById(req.params.id).populate('owner', 'name email');
      if (!record) return _notFound(res);
      if (record.owner._id.toString() !== req.user.id && req.user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Access denied.' });
      }
      return res.status(200).json({ success: true, data: record });
    } catch (err) {
      console.error('getRecordById error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // PUT /api/:module/:id/upload  — upload a file into a specific slot
  // Body fields: slotKey (e.g. 'team', 'directTax', 'strategicRisks')
  const uploadSlotFile = async (req, res) => {
    try {
      const record = await _ownedRecord(Model, req.params.id, req.user.id);
      if (!record) return _notFound(res);

      const { slotKey } = req.body;
      if (!slotKey) {
        return res.status(400).json({ success: false, message: 'slotKey is required.' });
      }
      if (record[slotKey] === undefined) {
        return res.status(400).json({ success: false, message: `Unknown slotKey: ${slotKey}` });
      }
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'No file received.' });
      }

      _deleteOldFile(record[slotKey]?.fileUrl);

      const extractedText = await extractTextFromFile(req.file.path, req.file.originalname);
      record.set(slotKey, {
        fileUrl:       `/uploads/${req.file.filename}`,
        fileName:      req.file.originalname,
        fileSize:      req.file.size,
        uploadedAt:    new Date(),
        extractedText,
      });
      record.markModified(slotKey);
      record.status = 'in_progress';
      record.updatedAt = new Date();
      await record.save();

      console.log(`[${Model.modelName}.${slotKey}] Stored: ${req.file.originalname} | Chars: ${extractedText.length}`);

      return res.status(200).json({
        success: true,
        message: `${slotKey} uploaded.`,
        data: {
          fileName:   record[slotKey].fileName,
          fileUrl:    record[slotKey].fileUrl,
          uploadedAt: record[slotKey].uploadedAt,
        },
      });
    } catch (err) {
      console.error('uploadSlotFile error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // GET /api/:module/:id/data  — returns all extracted texts + aiReport
  const getModuleData = async (req, res) => {
    try {
      const record = await _ownedRecord(Model, req.params.id, req.user.id);
      if (!record) return _notFound(res);

      const obj = record.toObject();
      const extracted = {};
      Object.entries(obj).forEach(([key, val]) => {
        if (key !== 'aiReport' && val && typeof val === 'object' && val.extractedText) {
          extracted[key] = val.extractedText;
        }
      });

      return res.status(200).json({
        success: true,
        data: { module: Model.modelName, extracted, aiReport: obj.aiReport || null },
      });
    } catch (err) {
      console.error('getModuleData error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // POST /api/:module/:id/ai-report  — save AI report + auto-generate PDF
  const saveAiReport = async (req, res) => {
    try {
      const record = await _ownedRecord(Model, req.params.id, req.user.id);
      if (!record) return _notFound(res);

      const reportData = {
        verdict:             req.body.verdict,
        summary:             req.body.summary,
        overallScore:        req.body.overallScore,
        financialScore:      req.body.financialScore,
        operationalScore:    req.body.operationalScore,
        legalScore:          req.body.legalScore,
        recoveryScore:       req.body.recoveryScore,
        strategicScore:      req.body.strategicScore,
        complianceScore:     req.body.complianceScore,
        teamScore:           req.body.teamScore,
        operationScore:      req.body.operationScore,
        policyScore:         req.body.policyScore,
        challengeScore:      req.body.challengeScore,
        scores:              req.body.scores || {},
        strengths:           req.body.strengths,
        risks:               req.body.risks,
        opportunities:       req.body.opportunities,
        recommendations:     req.body.recommendations,
        finalRecommendation: req.body.finalRecommendation,
        rawText:             req.body.rawText || '',
        generatedAt:         new Date(),
      };

      record.set('aiReport', reportData);
      record.status = 'ai_complete';
      record.updatedAt = new Date();
      await record.save();

      // Auto-generate PDF
      let pdfUrl = null;
      try {
        pdfUrl = await _generatePdf(record, Model.modelName);
        if (pdfUrl) {
          record.set('aiReport.pdfUrl', pdfUrl);
          await record.save();
        }
      } catch (pdfErr) {
        console.error(`[${Model.modelName}] PDF generation failed:`, pdfErr.message);
      }

      return res.status(200).json({
        success: true,
        message: `AI report saved for ${Model.modelName}`,
        data: record.aiReport,
        pdfUrl,
      });
    } catch (err) {
      console.error('saveAiReport error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // DELETE /api/:module/:id
  const deleteRecord = async (req, res) => {
    try {
      const record = await _ownedRecord(Model, req.params.id, req.user.id);
      if (!record) return _notFound(res);
      await Model.findByIdAndDelete(req.params.id);
      return res.status(200).json({ success: true, message: 'Record deleted.' });
    } catch (err) {
      console.error('deleteRecord error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // GET /api/:module/:id/report/pdf
  const downloadReportPdf = async (req, res) => {
    try {
      const record = await _ownedRecord(Model, req.params.id, req.user.id);
      if (!record) return _notFound(res);

      if (!record.aiReport) {
        return res.status(404).json({ success: false, message: 'No AI report found. Generate report first.' });
      }

      let pdfPath = null;
      if (record.aiReport.pdfUrl) {
        const stored = path.join(__dirname, '..', record.aiReport.pdfUrl);
        if (fs.existsSync(stored)) pdfPath = stored;
      }

      if (!pdfPath) {
        const pdfUrl = await _generatePdf(record, Model.modelName);
        if (pdfUrl) {
          record.set('aiReport.pdfUrl', pdfUrl);
          await record.save();
          pdfPath = path.join(__dirname, '..', pdfUrl);
        }
      }

      if (!pdfPath || !fs.existsSync(pdfPath)) {
        return res.status(500).json({ success: false, message: 'PDF generation failed.' });
      }

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="empora_${Model.modelName}_report.pdf"`);
      fs.createReadStream(pdfPath).pipe(res);
    } catch (err) {
      console.error('downloadReportPdf error:', err);
      return res.status(500).json({ success: false, message: 'Server error.' });
    }
  };

  // POST /api/:module/:id/generate-ai
  // Reads extracted text from all slots, calls Groq AI server-side, saves & returns report.
  const generateAiReport = async (req, res) => {
    try {
      const record = await _ownedRecord(Model, req.params.id, req.user.id);
      if (!record) return _notFound(res);

      // ── 1. Collect extracted text from all document slots ──────────────────
      const moduleLabels = {
        team:        'TEAM PROFILE',
        businessDev: 'BUSINESS DEVELOPMENT',
        risk:        'RISK OVERVIEW',
        operation:   'OPERATIONS',
        policy:      'POLICY',
        challenges:  'CHALLENGES',
        profile:     'COMPANY PROFILE',
      };

      let docSection = '';
      let hasContent  = false;
      const obj = record.toObject();

      for (const [key, label] of Object.entries(moduleLabels)) {
        const slot    = obj[key];
        const content = (slot?.extractedText || '').trim();
        if (content) {
          docSection += `=== ${label} ===\n${content.substring(0, 1500)}${content.length > 1500 ? '...' : ''}\n\n`;
          hasContent = true;
        }
      }

      if (!hasContent) {
        docSection = '[No document text could be extracted. Provide general strategic guidance based on module names.]\n';
      }

      // ── 2. Build AI prompt ─────────────────────────────────────────────────
      const prompt = `You are a senior business strategist with 20+ years of experience.
Analyse the following strategy documents submitted by a company and produce a comprehensive report.
Base your ENTIRE analysis on the actual content provided below — do NOT use placeholder text.

${docSection}
Return ONLY this valid JSON (no markdown fences, no preamble, nothing else):
{
  "verdict": "STRONG" | "MODERATE" | "WEAK",
  "summary": "3-4 sentence executive summary referencing specific content from the documents",
  "overallScore": 0.0,
  "teamScore": 0.0,
  "operationScore": 0.0,
  "policyScore": 0.0,
  "challengeScore": 0.0,
  "strengths": ["Specific strength from documents", "Strength 2", "Strength 3"],
  "risks": ["Specific risk from documents", "Risk 2", "Risk 3"],
  "opportunities": ["Opportunity from documents", "Opportunity 2", "Opportunity 3"],
  "recommendations": ["Actionable recommendation 1", "Recommendation 2", "Recommendation 3"],
  "finalRecommendation": "3-4 sentence paragraph with specific actionable next steps from the documents."
}
All scores must be between 0.0 and 1.0. Arrays must have at least 2 items each.
NEVER use text like 'Documents uploaded', 'retry', 'API key', or 'service unavailable'.`;

      // ── 3. Call Groq AI ────────────────────────────────────────────────────
      const groqKey = process.env.GROQ_API_KEY;
      if (!groqKey) {
        return res.status(500).json({ success: false, message: 'GROQ_API_KEY not configured on server.' });
      }

      const axios = require('axios');
      let rawResponse;

      try {
        const groqRes = await axios.post(
          'https://api.groq.com/openai/v1/chat/completions',
          {
            model: 'mixtral-8x7b-32768',
            messages: [
              {
                role: 'system',
                content: 'You are a senior business strategist. Respond ONLY with valid JSON. No markdown fences, no preamble. Your entire response must be parseable by JSON.parse().',
              },
              { role: 'user', content: prompt },
            ],
            temperature: 0.2,
            max_tokens:  2000,
          },
          {
            headers: {
              Authorization: `Bearer ${groqKey}`,
              'Content-Type': 'application/json',
            },
            timeout: 90000,
          }
        );
        rawResponse = groqRes.data?.choices?.[0]?.message?.content || '';
      } catch (aiErr) {
        console.error('Groq API error:', aiErr.response?.data || aiErr.message);
        return res.status(502).json({
          success: false,
          message: `AI service error: ${aiErr.response?.data?.error?.message || aiErr.message}`,
        });
      }

      // ── 4. Parse JSON ──────────────────────────────────────────────────────
      let aiData;
      try {
        let text = rawResponse.trim().replace(/^```[a-z]*\n?/, '').replace(/```$/, '').trim();
        aiData = JSON.parse(text);
      } catch (parseErr) {
        console.error('AI JSON parse failed. Raw:', rawResponse.substring(0, 300));
        return res.status(500).json({
          success: false,
          message: 'AI returned an invalid format. Please tap Retry.',
        });
      }

      // ── 5. Save to MongoDB & auto-generate PDF ─────────────────────────────
      const reportData = {
        verdict:             aiData.verdict             || 'MODERATE',
        summary:             aiData.summary             || '',
        overallScore:        Number(aiData.overallScore)    || 0.5,
        teamScore:           Number(aiData.teamScore)       || 0.5,
        operationScore:      Number(aiData.operationScore)  || 0.5,
        policyScore:         Number(aiData.policyScore)     || 0.5,
        challengeScore:      Number(aiData.challengeScore)  || 0.5,
        strengths:           Array.isArray(aiData.strengths)       ? aiData.strengths       : [],
        risks:               Array.isArray(aiData.risks)           ? aiData.risks           : [],
        opportunities:       Array.isArray(aiData.opportunities)   ? aiData.opportunities   : [],
        recommendations:     Array.isArray(aiData.recommendations) ? aiData.recommendations : [],
        finalRecommendation: aiData.finalRecommendation || '',
        rawText:             rawResponse,
        generatedAt:         new Date(),
      };

      record.set('aiReport', reportData);
      record.status = 'ai_complete';
      await record.save();

      // Auto-generate PDF (non-blocking — don't fail if PDF fails)
      let pdfUrl = null;
      try {
        pdfUrl = await _generatePdf(record, Model.modelName);
        if (pdfUrl) {
          record.set('aiReport.pdfUrl', pdfUrl);
          await record.save();
        }
      } catch (pdfErr) {
        console.error(`[${Model.modelName}] PDF generation failed:`, pdfErr.message);
      }

      return res.status(200).json({
        success: true,
        data: { aiReport: record.aiReport },
        pdfUrl,
      });

    } catch (err) {
      console.error('generateAiReport error:', err);
      return res.status(500).json({ success: false, message: err.message || 'Server error.' });
    }
  };

  return { createRecord, getMyRecords, getRecordById, uploadSlotFile, getModuleData, saveAiReport, generateAiReport, deleteRecord, downloadReportPdf };
}

// ─── PDF generation (same as before) ─────────────────────────────────────────
async function _generatePdf(record, moduleName) {
  const r = record.aiReport;
  if (!r) return null;

  const PDFDocument = require('pdfkit');
  const uploadsDir  = path.join(__dirname, '..', 'uploads');
  if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

  if (r.pdfUrl) {
    try {
      const old = path.join(__dirname, '..', r.pdfUrl);
      if (fs.existsSync(old)) fs.unlinkSync(old);
    } catch (_) {}
  }

  const fileName = `report_${moduleName}_${record._id}_${Date.now()}.pdf`;
  const filePath = path.join(uploadsDir, fileName);
  const fileUrl  = `/uploads/${fileName}`;

  const colours = {
    Restructure:       '#B45309', RiskManagement:    '#B91C1C',
    ProjectManagement: '#0369A1', CyberSecurity:     '#6D28D9',
    Stratic:           '#0D6E8A', Taxation:          '#0D6E8A',
    LandLegal:         '#B45309', Licence:           '#047857',
    Loans:             '#1A3A6B',
  };
  const PRIMARY = colours[moduleName] || '#1E293B';
  const TEXT    = '#1E293B';
  const MUTED   = '#64748B';
  const WHITE   = '#FFFFFF';
  const PAGE_W  = 495;
  const LEFT    = 50;
  const sc      = (v) => (v >= 0.7 ? '#16A34A' : v >= 0.4 ? '#D97706' : '#DC2626');

  await new Promise((resolve, reject) => {
    const doc    = new PDFDocument({ margin: 50, size: 'A4', bufferPages: true });
    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);
    stream.on('finish', resolve);
    stream.on('error', reject);

    doc.rect(0, 0, doc.page.width, 160).fill(PRIMARY);
    doc.fontSize(22).font('Helvetica-Bold').fillColor(WHITE)
       .text(`AI ${moduleName} Report`, LEFT, 30);
    doc.fontSize(9).font('Helvetica').fillColor('rgba(255,255,255,0.65)')
       .text(`Empora Intelligence Platform  ·  ${new Date().toDateString()}`, LEFT, 58);

    const vCol = (r.verdict || '').includes('VIABLE') ? '#16A34A'
               : (r.verdict || '').includes('NEEDS')  ? '#D97706' : '#DC2626';
    doc.roundedRect(LEFT, 78, 240, 22, 11).fill(vCol);
    doc.fontSize(9).font('Helvetica-Bold').fillColor(WHITE)
       .text(r.verdict || 'N/A', LEFT + 10, 84, { width: 220 });

    const pct = ((r.overallScore || 0) * 100).toFixed(0) + '%';
    doc.circle(doc.page.width - 80, 64, 36).fill('rgba(255,255,255,0.2)');
    doc.fontSize(17).font('Helvetica-Bold').fillColor(WHITE)
       .text(pct, doc.page.width - 104, 52, { width: 50, align: 'center' });

    doc.moveDown(8);

    const checkPage = (h = 80) => { if (doc.y + h > doc.page.height - 70) doc.addPage(); };
    const sectionHeader = (title) => {
      checkPage(40);
      doc.moveDown(0.4);
      const y = doc.y;
      doc.rect(LEFT, y, 4, 18).fill(PRIMARY);
      doc.rect(LEFT + 4, y, PAGE_W - 4, 18).fill('#F8FAFC');
      doc.fontSize(12).font('Helvetica-Bold').fillColor(TEXT)
         .text(title, LEFT + 14, y + 3, { width: PAGE_W - 20 });
      doc.moveDown(0.8);
    };
    const bodyText = (t) => {
      checkPage(50);
      doc.fontSize(10.5).font('Helvetica').fillColor(TEXT)
         .text(t || '—', LEFT, doc.y, { width: PAGE_W, lineGap: 3 });
      doc.moveDown(0.5);
    };
    const bullets = (items = [], col = PRIMARY) => {
      items.forEach(item => {
        checkPage(22);
        const y = doc.y;
        doc.roundedRect(LEFT, y + 5, 6, 6, 3).fill(col);
        doc.fontSize(10.5).font('Helvetica').fillColor(TEXT)
           .text(item, LEFT + 14, y, { width: PAGE_W - 14, lineGap: 2 });
        doc.moveDown(0.3);
      });
      doc.moveDown(0.2);
    };
    const scoreBar = (lbl, score) => {
      checkPage(28);
      const barW = PAGE_W - 60;
      const fill = barW * Math.min(score || 0, 1);
      const y    = doc.y;
      doc.fontSize(9.5).font('Helvetica').fillColor(MUTED).text(lbl, LEFT, y);
      doc.font('Helvetica-Bold').fillColor(TEXT)
         .text(((score || 0) * 100).toFixed(0) + '%', LEFT + barW - 20, y, { width: 50 });
      const barY = doc.y + 1;
      doc.roundedRect(LEFT, barY, barW, 7, 3.5).fill('#E2E8F0');
      if (fill > 2) doc.roundedRect(LEFT, barY, fill, 7, 3.5).fill(sc(score));
      doc.moveDown(1.3);
    };

    sectionHeader('Executive Summary');
    bodyText(r.summary);

    sectionHeader('Score Breakdown');
    scoreBar('Overall', r.overallScore);
    [
      ['Financial', r.financialScore], ['Operational', r.operationalScore],
      ['Legal', r.legalScore],         ['Recovery', r.recoveryScore],
      ['Strategic', r.strategicScore], ['Compliance', r.complianceScore],
      ['Team', r.teamScore],           ['Operation', r.operationScore],
      ['Policy', r.policyScore],       ['Challenge', r.challengeScore],
    ].forEach(([l, v]) => { if (v != null && v > 0) scoreBar(l, v); });

    const sm = r.scores instanceof Map ? Object.fromEntries(r.scores) : (r.scores || {});
    Object.entries(sm).forEach(([k, v]) => {
      scoreBar(k.replace(/([A-Z])/g, ' $1').trim(), v);
    });

    if ((r.strengths     || []).length) { sectionHeader('Strengths');      bullets(r.strengths,       '#16A34A'); }
    if ((r.risks         || []).length) { sectionHeader('Key Risks');       bullets(r.risks,           '#DC2626'); }
    if ((r.opportunities || []).length) { sectionHeader('Opportunities');   bullets(r.opportunities,   '#0891B2'); }
    if ((r.recommendations||[]).length) { sectionHeader('Recommendations'); bullets(r.recommendations, PRIMARY);  }

    sectionHeader('Final Recommendation');
    checkPage(90);
    const by = doc.y;
    doc.rect(LEFT, by, PAGE_W, 90).fill('#FEF9EC');
    doc.rect(LEFT, by, 4, 90).fill(PRIMARY);
    doc.fontSize(10.5).font('Helvetica').fillColor(TEXT)
       .text(r.finalRecommendation || '—', LEFT + 14, by + 10,
             { width: PAGE_W - 24, height: 72, lineGap: 3 });
    doc.moveDown(7);

    const range = doc.bufferedPageRange();
    for (let i = 0; i < range.count; i++) {
      doc.switchToPage(range.start + i);
      doc.rect(0, doc.page.height - 34, doc.page.width, 34).fill(PRIMARY);
      doc.fontSize(8).font('Helvetica').fillColor('rgba(255,255,255,0.7)')
         .text(
           `Empora AI  ·  ${moduleName} Module  ·  Confidential  ·  Page ${i + 1} of ${range.count}`,
           LEFT, doc.page.height - 20, { width: PAGE_W, align: 'center' }
         );
    }
    doc.end();
  });

  return fileUrl;
}

module.exports = { createModuleController };