// empora-backend/models/moduleSchemas.js
// Shared schemas reused by every module model

const mongoose = require('mongoose');

// ─── Reusable file slot ───────────────────────────────────────────────────────
const fileSlot = {
  fileName:      { type: String, default: null },
  fileUrl:       { type: String, default: null },
  fileSize:      { type: Number, default: null },
  extractedText: { type: String, default: '' },
  uploadedAt:    { type: Date,   default: null },
};

const DocSlotSchema = new mongoose.Schema({ ...fileSlot }, { _id: false });

// ─── Shared AI Report schema for all modules ─────────────────────────────────
const ModuleAiReportSchema = new mongoose.Schema({
  verdict:             { type: String, default: '' },
  summary:             { type: String, default: '' },
  overallScore:        { type: Number, default: 0 },
  financialScore:      { type: Number, default: 0 },
  operationalScore:    { type: Number, default: 0 },
  legalScore:          { type: Number, default: 0 },
  recoveryScore:       { type: Number, default: 0 },
  strategicScore:      { type: Number, default: 0 },
  complianceScore:     { type: Number, default: 0 },
  teamScore:           { type: Number, default: 0 },
  operationScore:      { type: Number, default: 0 },
  policyScore:         { type: Number, default: 0 },
  challengeScore:      { type: Number, default: 0 },
  scores:              { type: Map, of: Number, default: {} },
  strengths:           [{ type: String }],
  risks:               [{ type: String }],
  opportunities:       [{ type: String }],
  recommendations:     [{ type: String }],
  finalRecommendation: { type: String, default: '' },
  rawText:             { type: String, default: '' },
  generatedAt:         { type: Date,   default: null },
  pdfUrl:              { type: String, default: null },
}, { _id: false });

module.exports = { fileSlot, DocSlotSchema, ModuleAiReportSchema };