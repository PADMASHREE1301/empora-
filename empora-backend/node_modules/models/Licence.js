// empora-backend/models/Licence.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const LicenceSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    businessInfo: { type: DocSlotSchema, default: () => ({}) },
    applicationDocs: { type: DocSlotSchema, default: () => ({}) },
    permits: { type: DocSlotSchema, default: () => ({}) },
    renewals: { type: DocSlotSchema, default: () => ({}) },
    compliance: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'licences' }
);

module.exports = mongoose.model('Licence', LicenceSchema);