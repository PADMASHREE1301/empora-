// empora-backend/controllers/fundRaisingController.js
//
// DEPENDENCIES — run once in your backend folder:
//   npm install pdf-parse mammoth xlsx adm-zip pdfkit

const FundRaising = require('../models/FundRaising');
const path = require('path');
const fs   = require('fs');

// ─── Text extraction helper ───────────────────────────────────────────────────

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

// ─── @route  POST /api/fund/create ───────────────────────────────────────────
exports.createFundRaising = async (req, res) => {
  try {
    const {
      company, sector, fundingGoal, askAmount,
      businessIdea, problemStatement, solution,
      marketSize, revenueModel, teamDetails,
    } = req.body;

    if (!company || !sector || !businessIdea) {
      return res.status(400).json({
        success: false,
        message: 'Company name, sector and business idea are required.',
      });
    }

    const record = await FundRaising.create({
      owner: req.user.id,
      pitchDeck: {
        company, sector, fundingGoal, askAmount,
        businessIdea, problemStatement, solution,
        marketSize, revenueModel, teamDetails,
      },
      status: 'draft',
    });

    return res.status(201).json({
      success: true,
      message: 'Fundraising record created.',
      data: record,
    });
  } catch (err) {
    console.error('CreateFundRaising error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  GET /api/fund/my ─────────────────────────────────────────────────
exports.getMyFundRaisings = async (req, res) => {
  try {
    const records = await FundRaising.find({ owner: req.user.id })
      .sort({ updatedAt: -1 })
      .select('-__v');
    return res.status(200).json({ success: true, count: records.length, data: records });
  } catch (err) {
    console.error('GetMyFundRaisings error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  GET /api/fund/:id ────────────────────────────────────────────────
exports.getFundRaisingById = async (req, res) => {
  try {
    const record = await FundRaising.findById(req.params.id).populate('owner', 'name email');
    if (!record) return _notFound(res);
    if (record.owner._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }
    return res.status(200).json({ success: true, data: record });
  } catch (err) {
    console.error('GetFundRaisingById error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  GET /api/fund/:id/extracted-text ────────────────────────────────
exports.getExtractedText = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    return res.status(200).json({
      success: true,
      data: {
        pitchDeckText:   record.pitchDeck?.extractedText || '',
        valuationText:   record.valuation?.extractedText || '',
        commentsText:    record.comments?.extractedText  || '',
        pitchDeckFields: {
          company:          record.pitchDeck?.company          || '',
          sector:           record.pitchDeck?.sector           || '',
          fundingGoal:      record.pitchDeck?.fundingGoal      || '',
          askAmount:        record.pitchDeck?.askAmount        || '',
          businessIdea:     record.pitchDeck?.businessIdea     || '',
          problemStatement: record.pitchDeck?.problemStatement || '',
          solution:         record.pitchDeck?.solution         || '',
          marketSize:       record.pitchDeck?.marketSize       || '',
          revenueModel:     record.pitchDeck?.revenueModel     || '',
          teamDetails:      record.pitchDeck?.teamDetails      || '',
        },
        valuationFields: {
          requiredFunding:  record.valuation?.requiredFunding  || '',
          equityOffered:    record.valuation?.equityOffered    || '',
          impliedValuation: record.valuation?.impliedValuation || '',
          currentRevenue:   record.valuation?.currentRevenue   || '',
          expenses:         record.valuation?.expenses         || '',
          profitMargin:     record.valuation?.profitMargin     || '',
          growthRate:       record.valuation?.growthRate       || '',
        },
        commentsFields: {
          businessBackground: record.comments?.businessBackground || '',
          experience:         record.comments?.experience         || '',
          competitorDetails:  record.comments?.competitorDetails  || '',
          riskFactors:        record.comments?.riskFactors        || '',
          futurePlan:         record.comments?.futurePlan         || '',
          useOfFunds:         record.comments?.useOfFunds         || '',
          traction:           record.comments?.traction           || '',
          stage:              record.comments?.stage              || '',
        },
      },
    });
  } catch (err) {
    console.error('GetExtractedText error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  PUT /api/fund/:id/pitch-deck ────────────────────────────────────
exports.updatePitchDeck = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const fields = [
      'company', 'sector', 'fundingGoal', 'askAmount',
      'businessIdea', 'problemStatement', 'solution',
      'marketSize', 'revenueModel', 'teamDetails',
    ];
    fields.forEach((f) => { if (req.body[f] !== undefined) record.pitchDeck[f] = req.body[f]; });

    if (req.file) {
      _deleteOldFile(record.pitchDeck.fileUrl);
      record.pitchDeck.fileUrl   = `/uploads/${req.file.filename}`;
      record.pitchDeck.fileName  = req.file.originalname;
      record.pitchDeck.fileSize  = req.file.size;
      record.pitchDeck.uploadedAt = new Date();
      record.pitchDeck.extractedText = await extractTextFromFile(req.file.path, req.file.originalname);
      console.log(`[PitchDeck] Extracted ${record.pitchDeck.extractedText.length} chars`);
    }

    record.pitchDeck.isComplete = _isPitchComplete(record.pitchDeck);
    record.updatedAt = new Date();
    await record.save();

    return res.status(200).json({ success: true, message: 'Pitch deck saved.', data: record.pitchDeck });
  } catch (err) {
    console.error('UpdatePitchDeck error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  PUT /api/fund/:id/valuation ─────────────────────────────────────
exports.updateValuation = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const fields = ['requiredFunding', 'equityOffered', 'currentRevenue',
                    'expenses', 'profitMargin', 'growthRate', 'impliedValuation'];
    fields.forEach((f) => { if (req.body[f] !== undefined) record.valuation[f] = req.body[f]; });

    if (req.file) {
      _deleteOldFile(record.valuation.fileUrl);
      record.valuation.fileUrl    = `/uploads/${req.file.filename}`;
      record.valuation.fileName   = req.file.originalname;
      record.valuation.fileSize   = req.file.size;
      record.valuation.uploadedAt = new Date();
      record.valuation.extractedText = await extractTextFromFile(req.file.path, req.file.originalname);
      console.log(`[Valuation] Extracted ${record.valuation.extractedText.length} chars`);
    }

    record.valuation.isComplete = !!record.valuation.requiredFunding && !!record.valuation.equityOffered;
    record.updatedAt = new Date();
    await record.save();

    return res.status(200).json({ success: true, message: 'Valuation saved.', data: record.valuation });
  } catch (err) {
    console.error('UpdateValuation error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  PUT /api/fund/:id/comments ──────────────────────────────────────
exports.updateComments = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const fields = ['businessBackground', 'experience', 'competitorDetails',
                    'riskFactors', 'futurePlan', 'useOfFunds', 'traction', 'stage'];
    fields.forEach((f) => { if (req.body[f] !== undefined) record.comments[f] = req.body[f]; });

    if (Array.isArray(req.body.investorComments)) {
      record.comments.investorComments.push(...req.body.investorComments);
    }

    if (req.file) {
      // For comments, the slot key tells us which sub-field to populate
      // e.g. fields: { businessBackground: 'strategicRisks' } means
      // store under riskManagement.strategicRisks
      const slotKey  = req.body.businessBackground; // slot key sent by Flutter
      const module   = _detectModule(slotKey);

      if (module && module !== 'fundraising') {
        // ── Store in the correct module slot ──────────────────────────────────
        if (!record[module]) record[module] = {};
        if (!record[module][slotKey]) record[module][slotKey] = {};

        _deleteOldFile(record[module][slotKey].fileUrl);
        record[module][slotKey].fileUrl    = `/uploads/${req.file.filename}`;
        record[module][slotKey].fileName   = req.file.originalname;
        record[module][slotKey].fileSize   = req.file.size;
        record[module][slotKey].uploadedAt = new Date();
        record[module][slotKey].extractedText =
          await extractTextFromFile(req.file.path, req.file.originalname);

        console.log(`[${module}.${slotKey}] Extracted ${record[module][slotKey].extractedText.length} chars`);
        record.markModified(module);
      } else {
        // Fallback: store extracted text in comments
        record.comments.extractedText = await extractTextFromFile(req.file.path, req.file.originalname);
        console.log(`[Comments] Extracted ${record.comments.extractedText.length} chars`);
      }
    }

    record.comments.isComplete = !!record.comments.businessBackground;
    record.updatedAt = new Date();
    await record.save();

    return res.status(200).json({ success: true, message: 'Saved.', data: record.comments });
  } catch (err) {
    console.error('UpdateComments error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  POST /api/fund/:id/ai-report ────────────────────────────────────
// Saves AI report for fundraising OR any other module
// Body must include: module (optional, defaults to 'fundraising')
exports.saveAiReport = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const moduleName = req.body.module || 'fundraising';

    const reportData = {
      verdict:             req.body.verdict,
      summary:             req.body.summary,
      overallScore:        req.body.overallScore,
      // Named score fields — each module sends different ones
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

    if (moduleName === 'fundraising') {
      // Legacy fundraising AI report fields
      record.aiReport = {
        ...reportData,
        pitchScore:     req.body.pitchScore,
        valuationScore: req.body.valuationScore,
        teamScore:      req.body.teamScore,
        marketScore:    req.body.marketScore,
        weaknesses:     req.body.weaknesses,
      };
      record.status = 'ai_complete';
    } else {
      // Module AI report — use record.set() for reliable nested tracking
      if (record[moduleName] === undefined) {
        return res.status(400).json({ success: false, message: `Unknown module: ${moduleName}` });
      }
      record.set(`${moduleName}.aiReport`, reportData);
      record.markModified(moduleName);
    }

    record.updatedAt = new Date();
    await record.save();

    // ── Auto-generate PDF and store pdfUrl ────────────────────────────────────
    let pdfUrl = null;
    if (moduleName !== 'fundraising') {
      try {
        pdfUrl = await _generateAndSaveModulePdf(record, moduleName);
        if (pdfUrl) {
          record.set(`${moduleName}.aiReport.pdfUrl`, pdfUrl);
          record.markModified(moduleName);
          await record.save();
          console.log(`[${moduleName}] PDF auto-saved: ${pdfUrl}`);
        }
      } catch (pdfErr) {
        console.error(`[${moduleName}] PDF generation failed:`, pdfErr.message);
        // Non-fatal — report is saved, PDF can be streamed on demand
      }
    }

    const savedReport = moduleName === 'fundraising'
      ? record.aiReport
      : record[moduleName]?.aiReport;

    return res.status(200).json({
      success: true,
      message: `AI report saved for module: ${moduleName}`,
      data:    savedReport,
      pdfUrl,   // ← returned directly so Flutter doesn't need a second fetch
    });
  } catch (err) {
    console.error('SaveAiReport error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  PUT /api/fund/:id/module-upload ─────────────────────────────────
// Generic endpoint for uploading any module document
// Body fields: module (e.g. 'riskManagement'), slotKey (e.g. 'strategicRisks')
exports.uploadModuleFile = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const { module: moduleName, slotKey } = req.body;

    if (!moduleName || !slotKey) {
      return res.status(400).json({ success: false, message: 'module and slotKey are required.' });
    }

    // Validate module exists
    if (record[moduleName] === undefined) {
      return res.status(400).json({ success: false, message: `Unknown module: ${moduleName}` });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file received.' });
    }

    // Delete previous file for this slot if any
    _deleteOldFile(record[moduleName][slotKey]?.fileUrl);

    // Use dot-notation so Mongoose correctly tracks the nested change
    const extractedText = await extractTextFromFile(req.file.path, req.file.originalname);
    record.set(`${moduleName}.${slotKey}`, {
      fileUrl:       `/uploads/${req.file.filename}`,
      fileName:      req.file.originalname,
      fileSize:      req.file.size,
      uploadedAt:    new Date(),
      extractedText,
    });

    record.markModified(moduleName);
    console.log(`[${moduleName}.${slotKey}] Stored: ${req.file.originalname} | Chars: ${extractedText.length}`);

    record.updatedAt = new Date();
    await record.save();

    return res.status(200).json({
      success: true,
      message: `${moduleName}.${slotKey} uploaded.`,
      data: {
        fileName:   record[moduleName][slotKey].fileName,
        fileUrl:    record[moduleName][slotKey].fileUrl,
        uploadedAt: record[moduleName][slotKey].uploadedAt,
      },
    });
  } catch (err) {
    console.error('UploadModuleFile error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  GET /api/fund/:id/module/:moduleName ────────────────────────────
// Returns all extracted text for a module (used before AI generation)
exports.getModuleData = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const moduleName = req.params.moduleName;
    if (!record[moduleName]) {
      return res.status(400).json({ success: false, message: `Unknown module: ${moduleName}` });
    }

    const moduleData = record[moduleName].toObject ? record[moduleName].toObject() : record[moduleName];

    // Build extracted map — key: slotKey, value: extractedText
    const extracted = {};
    Object.entries(moduleData).forEach(([key, val]) => {
      if (key !== 'aiReport' && val && typeof val === 'object' && val.extractedText) {
        extracted[key] = val.extractedText;
      }
    });

    return res.status(200).json({
      success: true,
      data: {
        module:    moduleName,
        extracted,
        aiReport:  moduleData.aiReport || null,
      },
    });
  } catch (err) {
    console.error('GetModuleData error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  DELETE /api/fund/:id ────────────────────────────────────────────
exports.deleteFundRaising = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);
    _deleteOldFile(record.pitchDeck?.fileUrl);
    _deleteOldFile(record.valuation?.fileUrl);
    await FundRaising.findByIdAndDelete(req.params.id);
    return res.status(200).json({ success: true, message: 'Record deleted.' });
  } catch (err) {
    console.error('DeleteFundRaising error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route  GET /api/fund/all (admin) ───────────────────────────────────────
exports.getAllFundRaisings = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Admin only.' });
    }
    const { page = 1, limit = 20, status, sector } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (sector) filter['pitchDeck.sector'] = sector;

    const records = await FundRaising.find(filter)
      .populate('owner', 'name email role')
      .sort({ updatedAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .select('-__v');

    const total = await FundRaising.countDocuments(filter);
    return res.status(200).json({
      success: true, total,
      page: Number(page),
      pages: Math.ceil(total / limit),
      data: records,
    });
  } catch (err) {
    console.error('GetAllFundRaisings error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── Private helpers ──────────────────────────────────────────────────────────

async function _ownedRecord(recordId, userId) {
  const record = await FundRaising.findById(recordId);
  if (!record) return null;
  if (record.owner.toString() !== userId) return null;
  return record;
}

function _notFound(res) {
  return res.status(404).json({ success: false, message: 'Record not found or access denied.' });
}

function _isPitchComplete(pitchDeck) {
  return !!(pitchDeck.company && pitchDeck.sector && pitchDeck.businessIdea &&
            pitchDeck.problemStatement && pitchDeck.solution);
}

function _deleteOldFile(fileUrl) {
  if (!fileUrl) return;
  try {
    const fullPath = path.join(__dirname, '..', fileUrl);
    if (fs.existsSync(fullPath)) fs.unlinkSync(fullPath);
  } catch (_) {}
}

// Maps a slot key to its parent module name
function _detectModule(slotKey) {
  const map = {
    // Risk Management
    strategicRisks: 'riskManagement', financialRisks: 'riskManagement',
    operationalRisks: 'riskManagement', legalRisks: 'riskManagement',
    marketRisks: 'riskManagement', technologyRisks: 'riskManagement',
    mitigationControls: 'riskManagement',
    // Project Management
    projectOverview: 'projectManagement', scopeDeliverables: 'projectManagement',
    timeline: 'projectManagement', resources: 'projectManagement',
    budget: 'projectManagement', riskManagement: 'projectManagement',
    monitoringReporting: 'projectManagement',
    // Cyber Security
    securityGovernance: 'cyberSecurity', networkSecurity: 'cyberSecurity',
    applicationSecurity: 'cyberSecurity', dataProtection: 'cyberSecurity',
    endpointSecurity: 'cyberSecurity', incidentManagement: 'cyberSecurity',
    complianceCerts: 'cyberSecurity',
    // Restructure
    reasonRestructuring: 'restructure', financialPlan: 'restructure',
    operationalPlan: 'restructure', organizationalPlan: 'restructure',
    assetLiabilityReview: 'restructure', legalImpact: 'restructure',
    recoveryStrategy: 'restructure',
    // Stratic
    team: 'stratic', businessDev: 'stratic',
    risk: 'stratic', operation: 'stratic',
    policy: 'stratic', challenges: 'stratic',
    profile: 'stratic',
    // Taxation
    businessTaxProfile: 'taxation', directTax: 'taxation',
    indirectTax: 'taxation', tds: 'taxation',
    payrollTax: 'taxation', liabilities: 'taxation',
    taxPlanning: 'taxation',
    // Land Legal
    propertyOwnership: 'landLegal', titleDocuments: 'landLegal',
    zoningCompliance: 'landLegal', licenses: 'landLegal',
    contracts: 'landLegal', legalIssues: 'landLegal',
    governance: 'landLegal',
    // Licence
    businessRegistration: 'licence', industryLicences: 'licence',
    operationalLicences: 'licence', financialRegistrations: 'licence',
    renewalStatus: 'licence', filingCompliance: 'licence',
    riskAssessment: 'licence',
    // Loans
    loanOverview: 'loans', lenderDetails: 'loans',
    repaymentInfo: 'loans', collateral: 'loans',
    performanceHistory: 'loans', financialImpact: 'loans',
    riskAnalysis: 'loans',
  };
  return map[slotKey] || 'fundraising';
}
// ─── PDF generation helper ─────────────────────────────────────────────────────
async function _generateAndSaveModulePdf(record, moduleName) {
  const r = record[moduleName]?.aiReport;
  if (!r) return null;

  const PDFDocument = require('pdfkit');
  const uploadsDir  = require('path').join(__dirname, '..', 'uploads');
  if (!require('fs').existsSync(uploadsDir))
    require('fs').mkdirSync(uploadsDir, { recursive: true });

  // Delete previous PDF for this module/record
  if (r.pdfUrl) {
    try {
      const old = require('path').join(__dirname, '..', r.pdfUrl);
      if (require('fs').existsSync(old)) require('fs').unlinkSync(old);
    } catch (_) {}
  }

  const fileName = `report_${moduleName}_${record._id}_${Date.now()}.pdf`;
  const filePath = require('path').join(uploadsDir, fileName);
  const fileUrl  = `/uploads/${fileName}`;

  // Per-module accent colours
  const colours = {
    restructure:       '#B45309', riskManagement:    '#B91C1C',
    projectManagement: '#0369A1', cyberSecurity:     '#6D28D9',
    stratic:           '#0D6E8A', taxation:          '#0D6E8A',
    landLegal:         '#B45309', licence:           '#047857',
    loans:             '#1A3A6B',
  };
  const PRIMARY = colours[moduleName] || '#1E293B';
  const DARK    = PRIMARY;
  const TEXT    = '#1E293B';
  const MUTED   = '#64748B';
  const WHITE   = '#FFFFFF';
  const PAGE_W  = 495;
  const LEFT    = 50;
  const label   = moduleName.charAt(0).toUpperCase() + moduleName.slice(1);
  const sc      = (v) => (v >= 0.7 ? '#16A34A' : v >= 0.4 ? '#D97706' : '#DC2626');

  await new Promise((resolve, reject) => {
    const doc    = new PDFDocument({ margin: 50, size: 'A4', bufferPages: true });
    const stream = require('fs').createWriteStream(filePath);
    doc.pipe(stream);
    stream.on('finish', resolve);
    stream.on('error', reject);

    // ── Header band ─────────────────────────────────────────────────────────
    doc.rect(0, 0, doc.page.width, 160).fill(DARK);
    doc.fontSize(22).font('Helvetica-Bold').fillColor(WHITE)
       .text(`AI ${label} Report`, LEFT, 30);
    doc.fontSize(9).font('Helvetica').fillColor('rgba(255,255,255,0.65)')
       .text(`Empora Intelligence Platform  ·  ${new Date().toDateString()}`, LEFT, 58);

    // Verdict pill
    const vCol = (r.verdict || '').includes('VIABLE') ? '#16A34A'
               : (r.verdict || '').includes('NEEDS')  ? '#D97706' : '#DC2626';
    doc.roundedRect(LEFT, 78, 240, 22, 11).fill(vCol);
    doc.fontSize(9).font('Helvetica-Bold').fillColor(WHITE)
       .text(r.verdict || 'N/A', LEFT + 10, 84, { width: 220 });

    // Score circle
    const pct = ((r.overallScore || 0) * 100).toFixed(0) + '%';
    doc.circle(doc.page.width - 80, 64, 36).fill(PRIMARY === DARK ? '#ffffff33' : PRIMARY);
    doc.fontSize(17).font('Helvetica-Bold').fillColor(WHITE)
       .text(pct, doc.page.width - 104, 52, { width: 50, align: 'center' });

    doc.moveDown(8);

    // ── Helpers ──────────────────────────────────────────────────────────────
    const checkPage = (h = 80) => {
      if (doc.y + h > doc.page.height - 70) doc.addPage();
    };
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

    // ── Sections ─────────────────────────────────────────────────────────────
    sectionHeader('Executive Summary');
    bodyText(r.summary);

    sectionHeader('Score Breakdown');
    scoreBar('Overall', r.overallScore);
    const named = [
      ['Financial', r.financialScore], ['Operational', r.operationalScore],
      ['Legal',     r.legalScore],     ['Recovery',    r.recoveryScore],
      ['Strategic', r.strategicScore], ['Compliance',  r.complianceScore],
      ['Team',      r.teamScore],      ['Operation',   r.operationScore],
      ['Policy',    r.policyScore],    ['Challenge',   r.challengeScore],
    ];
    named.forEach(([l, v]) => { if (v != null && v > 0) scoreBar(l, v); });
    const sm = r.scores instanceof Map ? Object.fromEntries(r.scores) : (r.scores || {});
    Object.entries(sm).forEach(([k, v]) => {
      scoreBar(k.replace(/([A-Z])/g, ' $1').trim(), v);
    });

    if ((r.strengths     || []).length) { sectionHeader('Strengths');       bullets(r.strengths,       '#16A34A'); }
    if ((r.risks         || []).length) { sectionHeader('Key Risks');        bullets(r.risks,           '#DC2626'); }
    if ((r.opportunities || []).length) { sectionHeader('Opportunities');    bullets(r.opportunities,   '#0891B2'); }
    if ((r.recommendations||[]).length) { sectionHeader('Recommendations');  bullets(r.recommendations, PRIMARY); }

    // Final recommendation box
    sectionHeader('Final Recommendation');
    checkPage(90);
    const by = doc.y;
    doc.rect(LEFT, by, PAGE_W, 90).fill('#FEF9EC');
    doc.rect(LEFT, by, 4, 90).fill(PRIMARY);
    doc.fontSize(10.5).font('Helvetica').fillColor(TEXT)
       .text(r.finalRecommendation || '—', LEFT + 14, by + 10,
             { width: PAGE_W - 24, height: 72, lineGap: 3 });
    doc.moveDown(7);

    // ── Footer on every page ─────────────────────────────────────────────────
    const range = doc.bufferedPageRange();
    for (let i = 0; i < range.count; i++) {
      doc.switchToPage(range.start + i);
      doc.rect(0, doc.page.height - 34, doc.page.width, 34).fill(DARK);
      doc.fontSize(8).font('Helvetica').fillColor('rgba(255,255,255,0.7)')
         .text(
           `Empora AI  ·  ${label} Module  ·  Confidential  ·  Page ${i + 1} of ${range.count}`,
           LEFT, doc.page.height - 20, { width: PAGE_W, align: 'center' }
         );
    }
    doc.end();
  });

  return fileUrl;
}

// ─── @route  GET /api/fund/:id/module/:moduleName/report/pdf ──────────────────
// Streams the stored PDF or generates on-the-fly if pdfUrl missing
exports.downloadModuleReportPdf = async (req, res) => {
  try {
    const record = await _ownedRecord(req.params.id, req.user.id);
    if (!record) return _notFound(res);

    const moduleName = req.params.moduleName;
    if (!record[moduleName]) {
      return res.status(400).json({ success: false, message: `Unknown module: ${moduleName}` });
    }

    const aiReport = record[moduleName]?.aiReport;
    if (!aiReport) {
      return res.status(404).json({ success: false, message: 'No AI report found. Generate report first.' });
    }

    let pdfPath = null;

    // Try stored pdfUrl first
    if (aiReport.pdfUrl) {
      const stored = path.join(__dirname, '..', aiReport.pdfUrl);
      if (fs.existsSync(stored)) pdfPath = stored;
    }

    // Re-generate if file missing
    if (!pdfPath) {
      console.log(`[${moduleName}] PDF file missing — regenerating...`);
      const pdfUrl = await _generateAndSaveModulePdf(record, moduleName);
      if (pdfUrl) {
        record.set(`${moduleName}.aiReport.pdfUrl`, pdfUrl);
        record.markModified(moduleName);
        await record.save();
        pdfPath = path.join(__dirname, '..', pdfUrl);
      }
    }

    if (!pdfPath || !fs.existsSync(pdfPath)) {
      return res.status(500).json({ success: false, message: 'PDF generation failed.' });
    }

    const fileName = `empora_${moduleName}_report.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    fs.createReadStream(pdfPath).pipe(res);

  } catch (err) {
    console.error('DownloadModuleReportPdf error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};