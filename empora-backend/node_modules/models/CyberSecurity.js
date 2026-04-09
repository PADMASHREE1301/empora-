// empora-backend/models/CyberSecurity.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const CyberSecuritySchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    infrastructure: { type: DocSlotSchema, default: () => ({}) },
    policies: { type: DocSlotSchema, default: () => ({}) },
    incidents: { type: DocSlotSchema, default: () => ({}) },
    vulnerabilities: { type: DocSlotSchema, default: () => ({}) },
    compliance: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'cybersecurities' }
);

module.exports = mongoose.model('CyberSecurity', CyberSecuritySchema);