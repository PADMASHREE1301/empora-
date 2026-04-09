// empora-backend/models/LandLegal.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const LandLegalSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    property: { type: DocSlotSchema, default: () => ({}) },
    titleDeed: { type: DocSlotSchema, default: () => ({}) },
    legalDocs: { type: DocSlotSchema, default: () => ({}) },
    agreements: { type: DocSlotSchema, default: () => ({}) },
    disputes: { type: DocSlotSchema, default: () => ({}) },
    compliance: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'landlegals' }
);

module.exports = mongoose.model('LandLegal', LandLegalSchema);