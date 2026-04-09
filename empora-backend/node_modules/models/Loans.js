// empora-backend/models/Loans.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const LoansSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    financials: { type: DocSlotSchema, default: () => ({}) },
    businessPlan: { type: DocSlotSchema, default: () => ({}) },
    collateral: { type: DocSlotSchema, default: () => ({}) },
    bankStatements: { type: DocSlotSchema, default: () => ({}) },
    creditHistory: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'loans' }
);

module.exports = mongoose.model('Loans', LoansSchema);