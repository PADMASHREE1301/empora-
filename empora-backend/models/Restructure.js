// empora-backend/models/Restructure.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const RestructureSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    financialHealth: { type: DocSlotSchema, default: () => ({}) },
    operations: { type: DocSlotSchema, default: () => ({}) },
    workforce: { type: DocSlotSchema, default: () => ({}) },
    assets: { type: DocSlotSchema, default: () => ({}) },
    debtProfile: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'restructures' }
);

module.exports = mongoose.model('Restructure', RestructureSchema);