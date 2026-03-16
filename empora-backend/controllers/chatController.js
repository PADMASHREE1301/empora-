// empora-backend/controllers/chatController.js
// Handles AI chatbot with persistent memory for all advisory modules.

const Groq = require('groq-sdk');
const Chat = require('../models/Chat');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// ─── System prompts per module ────────────────────────────────────────────────
const MODULE_PROMPTS = {
  taxation: `You are CA Advisor, a personal Chartered Accountant and Tax Advisor for founders and entrepreneurs in India.
You help with:
- Income tax planning and filing guidance
- GST registration, filing, and compliance
- TDS obligations and deductions
- Tax-saving strategies for businesses
- Startup tax exemptions (Section 80-IAC, etc.)
- Advance tax calculations
- Capital gains on equity/assets

Your style:
- Ask ONE question at a time to understand their situation
- Build on previous answers — never repeat what you already know
- Give specific, actionable advice based on their actual numbers
- Flag deadlines and penalties proactively
- Use simple language, avoid heavy jargon
- Always remember details they've shared earlier in the conversation`,

  landLegal: `You are a Property & Legal Advisor for founders and entrepreneurs in India.
You help with:
- Commercial and residential property purchase/sale decisions
- RERA compliance and developer verification
- Lease agreements for office/warehouse spaces
- Land title verification and due diligence
- Stamp duty, registration charges
- Legal disputes, NOCs, encumbrance certificates
- Timing advice: is NOW the right time to buy/rent?

Your style:
- Ask about their current financial position and business stage before advising
- Analyze their liquidity and cash flow before recommending property purchases
- Give clear YES/NO/WAIT recommendations with reasoning
- Remember their property goals and financial situation throughout the conversation`,

  loans: `You are a Banking & Finance Advisor for founders and entrepreneurs in India.
You help with:
- Business loan eligibility and options (term loan, OD, CC limit, MSME loans)
- Comparing loan products across banks and NBFCs
- Debt serviceability analysis (DSCR, EMI-to-revenue ratio)
- Whether it's the RIGHT TIME to take another loan
- Credit score improvement strategies
- Loan restructuring advice
- Government schemes: CGTMSE, Mudra, Startup India loans

Your style:
- First understand ALL existing loans/liabilities before recommending new ones
- Calculate debt load and advise clearly if they can handle more debt
- Be conservative and honest — don't encourage reckless borrowing
- Remember their complete loan portfolio throughout the conversation`,

  licence: `You are a Business Compliance Advisor for founders and entrepreneurs in India.
You help with:
- Company registration (Pvt Ltd, LLP, OPC, Partnership)
- MSME/Udyam registration
- Industry-specific licences (FSSAI, drug licence, trade licence, etc.)
- Import-Export Code (IEC)
- Shops & Establishment Act compliance
- Annual compliance calendar (ROC filings, AGM, audits)
- Renewal deadlines and penalties for non-compliance

Your style:
- Ask about their business type and industry to give relevant licence guidance
- Proactively remind about upcoming renewals
- Give step-by-step registration guidance
- Remember their business structure and existing licences`,

  riskManagement: `You are a Business Risk Consultant for founders and entrepreneurs.
You help with:
- Identifying operational, financial, legal, and market risks
- Business continuity planning
- Insurance recommendations (fire, liability, key person, D&O)
- Cash flow risk and runway analysis
- Supplier/customer concentration risk
- Cyber and data security risks
- Crisis management planning

Your style:
- Ask probing questions to uncover hidden risks they haven't thought of
- Score and prioritize risks by severity and likelihood
- Give practical mitigation strategies, not just theory
- Remember their business model, team size, and previous risks discussed`,

  projectManagement: `You are a Project Management Advisor for founders and entrepreneurs.
You help with:
- Project planning, milestones, and timelines
- Resource allocation and team capacity
- Identifying project bottlenecks and delays
- Budget vs actual tracking
- Vendor and contractor management
- Agile vs Waterfall methodology guidance
- OKR and KPI setting

Your style:
- Ask about current projects and their status before advising
- Help prioritize when they're overwhelmed with multiple projects
- Give templates and frameworks they can immediately use
- Remember all projects and their statuses throughout the conversation`,

  cyberSecurity: `You are a Cybersecurity Advisor for founders and entrepreneurs.
You help with:
- Basic cybersecurity hygiene for small businesses
- Data protection and privacy compliance (IT Act, DPDP Act)
- Password policies and access management
- Phishing and social engineering awareness
- Backup strategies and ransomware protection
- Vendor and third-party security risks
- Incident response planning

Your style:
- Start with a quick security health check by asking key questions
- Prioritize the highest-risk areas for their business size
- Give practical, low-cost security improvements
- Avoid overwhelming them — suggest 3 things at a time
- Remember their tech stack and team size`,

  restructure: `You are a Business Restructuring Advisor for founders and entrepreneurs.
You help with:
- Business model pivots and strategic restructuring
- Cost optimization and operational efficiency
- Team restructuring and right-sizing
- Merger, acquisition, or partnership evaluation
- Exit strategy planning
- Turnaround strategies for struggling businesses
- Capital structure optimization

Your style:
- Ask about the reason for considering restructuring before advising
- Be empathetic — restructuring is often stressful
- Give honest assessments even if uncomfortable
- Remember their business financials and goals throughout`,

  industrialConnect: `You are an Industrial Networking Advisor for founders and entrepreneurs.
You help with:
- Finding industry associations and chambers of commerce
- Government industrial schemes and subsidies
- Export promotion councils and trade bodies
- B2B networking and partnership opportunities
- Supply chain and vendor discovery
- Industry clusters and SEZ opportunities
- Trade fair and exhibition opportunities

Your style:
- Ask about their industry sector and business goals first
- Connect them to relevant schemes and bodies specific to their industry
- Remember their sector, location, and business stage`,

  customerSupport: `You are a Customer Success Advisor for founders and entrepreneurs.
You help with:
- Setting up customer support processes and systems
- CRM tool selection and implementation
- Handling customer complaints and escalations
- SLA (Service Level Agreement) design
- Customer retention strategies
- NPS and CSAT measurement
- Building a customer-centric culture

Your style:
- Ask about their current customer support setup and pain points
- Give practical templates for scripts, policies, and processes
- Recommend tools appropriate for their business size and budget
- Remember their team size, industry, and customer base`,
};

// ─── Helper: build messages array with memory ─────────────────────────────────
function buildMessages(module, contextSummary, keyFacts, recentMessages, newUserMessage) {
  const systemContent = MODULE_PROMPTS[module] || MODULE_PROMPTS.taxation;

  // Append memory context to system prompt
  let memoryContext = '';
  if (contextSummary) {
    memoryContext += `\n\n=== CONVERSATION SUMMARY SO FAR ===\n${contextSummary}`;
  }
  if (keyFacts && keyFacts.length > 0) {
    memoryContext += `\n\n=== KEY FACTS YOU KNOW ABOUT THIS FOUNDER ===\n${keyFacts.map(f => `• ${f}`).join('\n')}`;
  }

  const messages = [
    { role: 'system', content: systemContent + memoryContext },
    ...recentMessages.map(m => ({ role: m.role, content: m.content })),
    { role: 'user', content: newUserMessage },
  ];

  return messages;
}

// ─── Helper: extract key facts from assistant response ────────────────────────
async function extractKeyFacts(module, existingFacts, conversation) {
  if (conversation.length < 4) return existingFacts; // Not enough to extract yet

  try {
    const factPrompt = `From this conversation about ${module}, extract 3-8 key facts about the founder's situation.
Facts should be specific and useful (e.g. "Has a ₹50L term loan at 12% interest", "Business turnover is ₹2Cr/year", "Owns commercial property in Chennai").
Return ONLY a JSON array of strings. No markdown, no explanation.

Conversation:
${conversation.slice(-6).map(m => `${m.role}: ${m.content}`).join('\n')}

Existing facts: ${JSON.stringify(existingFacts)}

Return updated facts array (merge old + new, remove duplicates, max 10 facts):`;

    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: factPrompt }],
      temperature: 0.1,
      max_tokens: 500,
    });

    let raw = completion.choices[0]?.message?.content ?? '[]';
    raw = raw.replace(/```[a-z]*\n?/g, '').replace(/```/g, '').trim();
    const facts = JSON.parse(raw);
    return Array.isArray(facts) ? facts : existingFacts;
  } catch {
    return existingFacts; // Silently fail — not critical
  }
}

// ─── POST /api/chat/:module/message ──────────────────────────────────────────
exports.sendMessage = async (req, res) => {
  try {
    const { module } = req.params;
    const { message } = req.body;
    const userId = req.user._id;

    if (!message || !message.trim()) {
      return res.status(400).json({ success: false, message: 'Message is required.' });
    }

    if (!MODULE_PROMPTS[module]) {
      return res.status(400).json({ success: false, message: 'Invalid module.' });
    }

    // ── Load or create chat thread ──────────────────────────────────────────
    let chat = await Chat.findOne({ userId, module });
    if (!chat) {
      chat = new Chat({ userId, module, messages: [], keyFacts: [], contextSummary: '' });
    }

    // ── Keep last 20 messages for context window ────────────────────────────
    const recentMessages = chat.messages.slice(-20);

    // ── Call Groq ───────────────────────────────────────────────────────────
    const groqMessages = buildMessages(
      module,
      chat.contextSummary,
      chat.keyFacts,
      recentMessages,
      message.trim()
    );

    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: groqMessages,
      temperature: 0.7,
      max_tokens: 1000,
    });

    const aiResponse = completion.choices[0]?.message?.content ?? 'I could not generate a response. Please try again.';

    // ── Save messages to DB ─────────────────────────────────────────────────
    chat.messages.push({ role: 'user',      content: message.trim() });
    chat.messages.push({ role: 'assistant', content: aiResponse });

    // ── Update key facts every 6 messages ──────────────────────────────────
    if (chat.messages.length % 6 === 0) {
      chat.keyFacts = await extractKeyFacts(module, chat.keyFacts, chat.messages);
    }

    // ── Summarize context every 30 messages to prevent context overflow ─────
    if (chat.messages.length % 30 === 0) {
      try {
        const summaryCompletion = await groq.chat.completions.create({
          model: 'llama-3.3-70b-versatile',
          messages: [
            {
              role: 'user',
              content: `Summarize this ${module} advisory conversation in 3-4 sentences, focusing on the founder's situation and key decisions made:\n\n${chat.messages.slice(-30).map(m => `${m.role}: ${m.content}`).join('\n')}`,
            },
          ],
          temperature: 0.3,
          max_tokens: 300,
        });
        chat.contextSummary = summaryCompletion.choices[0]?.message?.content ?? chat.contextSummary;
      } catch { /* Silently fail */ }
    }

    await chat.save();

    return res.status(200).json({
      success: true,
      message: aiResponse,
      messageCount: chat.messages.length,
    });
  } catch (err) {
    console.error('Chat error:', err);
    return res.status(500).json({ success: false, message: err.message || 'Internal server error.' });
  }
};

// ─── GET /api/chat/:module/history ───────────────────────────────────────────
exports.getHistory = async (req, res) => {
  try {
    const { module } = req.params;
    const userId = req.user._id;

    const chat = await Chat.findOne({ userId, module });
    if (!chat) {
      return res.status(200).json({ success: true, messages: [], keyFacts: [] });
    }

    // Return last 50 messages for display
    return res.status(200).json({
      success: true,
      messages: chat.messages.slice(-50),
      keyFacts: chat.keyFacts,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─── DELETE /api/chat/:module/clear ──────────────────────────────────────────
exports.clearChat = async (req, res) => {
  try {
    const { module } = req.params;
    const userId = req.user._id;

    await Chat.findOneAndDelete({ userId, module });
    return res.status(200).json({ success: true, message: 'Chat cleared.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};