// empora-backend/models/Taxation.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const TaxationSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    income: { type: DocSlotSchema, default: () => ({}) },
    expenses: { type: DocSlotSchema, default: () => ({}) },
    assets: { type: DocSlotSchema, default: () => ({}) },
    compliance: { type: DocSlotSchema, default: () => ({}) },
    filings: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'taxations' }
);

module.exports = mongoose.model('Taxation', TaxationSchema);