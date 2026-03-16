// empora-backend/models/FundRaising.js
// FUNDRAISING collection only — modules now have their own collections

const mongoose = require('mongoose');
const { fileSlot } = require('./moduleSchemas');

const PitchDeckSchema = new mongoose.Schema({
  company: { type: String, default: '' }, sector: { type: String, default: '' },
  fundingGoal: { type: String, default: '' }, askAmount: { type: String, default: '' },
  businessIdea: { type: String, default: '' }, problemStatement: { type: String, default: '' },
  solution: { type: String, default: '' }, marketSize: { type: String, default: '' },
  revenueModel: { type: String, default: '' }, teamDetails: { type: String, default: '' },
  ...fileSlot, isComplete: { type: Boolean, default: false },
}, { _id: false });

const ValuationSchema = new mongoose.Schema({
  requiredFunding: { type: String, default: '' }, equityOffered: { type: String, default: '' },
  impliedValuation: { type: String, default: '' }, currentRevenue: { type: String, default: '' },
  expenses: { type: String, default: '' }, profitMargin: { type: String, default: '' },
  growthRate: { type: String, default: '' },
  ...fileSlot, isComplete: { type: Boolean, default: false },
}, { _id: false });

const CommentsSchema = new mongoose.Schema({
  businessBackground: { type: String, default: '' }, experience: { type: String, default: '' },
  competitorDetails: { type: String, default: '' }, riskFactors: { type: String, default: '' },
  futurePlan: { type: String, default: '' }, useOfFunds: { type: String, default: '' },
  traction: { type: String, default: '' }, stage: { type: String, default: '' },
  investorComments: [{ type: String }],
  ...fileSlot, isComplete: { type: Boolean, default: false },
}, { _id: false });

const FundraisingAiReportSchema = new mongoose.Schema({
  verdict: { type: String, default: '' }, summary: { type: String, default: '' },
  overallScore: { type: Number, default: 0 }, pitchScore: { type: Number, default: 0 },
  valuationScore: { type: Number, default: 0 }, teamScore: { type: Number, default: 0 },
  marketScore: { type: Number, default: 0 },
  strengths: [{ type: String }], weaknesses: [{ type: String }],
  opportunities: [{ type: String }], recommendations: [{ type: String }],
  finalRecommendation: { type: String, default: '' },
  rawText: { type: String, default: '' }, generatedAt: { type: Date, default: null },
}, { _id: false });

const FundRaisingSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User', required: true, index: true,
    },
    status: {
      type: String,
      enum: ['draft', 'in_progress', 'ai_complete', 'submitted', 'archived'],
      default: 'draft',
    },
    pitchDeck: { type: PitchDeckSchema,           default: () => ({}) },
    valuation:  { type: ValuationSchema,           default: () => ({}) },
    comments:   { type: CommentsSchema,            default: () => ({}) },
    aiReport:   { type: FundraisingAiReportSchema, default: null },
  },
  { timestamps: true }
);

FundRaisingSchema.pre('save', function (next) {
  if (
    this.pitchDeck?.isComplete &&
    this.valuation?.isComplete &&
    this.comments?.isComplete &&
    this.status === 'draft'
  ) {
    this.status = 'in_progress';
  }
  next();
});

module.exports = mongoose.model('FundRaising', FundRaisingSchema);