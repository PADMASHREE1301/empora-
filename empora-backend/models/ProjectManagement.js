// empora-backend/models/ProjectManagement.js
const mongoose = require('mongoose');
const { DocSlotSchema, ModuleAiReportSchema } = require('./moduleSchemas');

const ProjectManagementSchema = new mongoose.Schema(
  {
    owner:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:   {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    projectPlan: { type: DocSlotSchema, default: () => ({}) },
    timeline: { type: DocSlotSchema, default: () => ({}) },
    resources: { type: DocSlotSchema, default: () => ({}) },
    budget: { type: DocSlotSchema, default: () => ({}) },
    milestones: { type: DocSlotSchema, default: () => ({}) },
    documents: { type: DocSlotSchema, default: () => ({}) },
    aiReport: { type: ModuleAiReportSchema, default: null },
  },
  { timestamps: true, collection: 'projectmanagements' }
);

module.exports = mongoose.model('ProjectManagement', ProjectManagementSchema);