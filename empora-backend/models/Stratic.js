// empora-backend/models/Stratic.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const StraticSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status: {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    team:        { type: DocSlotSchema, default: () => ({}) },
    businessDev: { type: DocSlotSchema, default: () => ({}) },
    risk:        { type: DocSlotSchema, default: () => ({}) },
    operation:   { type: DocSlotSchema, default: () => ({}) },
    policy:      { type: DocSlotSchema, default: () => ({}) },
    challenges:  { type: DocSlotSchema, default: () => ({}) },
    profile:     { type: DocSlotSchema, default: () => ({}) },
    aiReport:    { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Stratic', StraticSchema);