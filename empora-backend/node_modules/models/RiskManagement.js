// empora-backend/models/RiskManagement.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const RiskManagementSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    operationalRisk: { type: DocSlotSchema, default: () => ({}) },
    financialRisk: { type: DocSlotSchema, default: () => ({}) },
    marketRisk: { type: DocSlotSchema, default: () => ({}) },
    legalRisk: { type: DocSlotSchema, default: () => ({}) },
    strategy: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'riskmanagements' }
);

module.exports = mongoose.model('RiskManagement', RiskManagementSchema);