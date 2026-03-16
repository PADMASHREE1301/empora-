// empora-backend/models/Chat.js
// Stores chatbot conversation history per user per module

const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  role:      { type: String, enum: ['user', 'assistant'], required: true },
  content:   { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
});

const chatSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    module: {
      type: String,
      required: true,
      enum: [
        'taxation',
        'landLegal',
        'loans',
        'licence',
        'riskManagement',
        'projectManagement',
        'cyberSecurity',
        'restructure',
        'industrialConnect',
        'customerSupport',
      ],
    },
    messages: [messageSchema],
    // Summary snapshot — updated every 10 messages for long-term memory
    contextSummary: { type: String, default: '' },
    // Key facts extracted from conversation (e.g. "has a ₹50L loan")
    keyFacts: [{ type: String }],
  },
  { timestamps: true }
);

// One chat thread per user per module
chatSchema.index({ userId: 1, module: 1 }, { unique: true });

module.exports = mongoose.model('Chat', chatSchema);