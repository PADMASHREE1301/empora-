// empora-backend/controllers/aiController.js
// Calls Groq API with the combined startup data and returns structured JSON.

const Groq = require('groq-sdk');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const SYSTEM_PROMPT = `You are an expert startup investor analyst with 20+ years of experience. 
Analyze startup fundraising applications and return structured investment reports.
Always respond with valid JSON only — no markdown code fences, no commentary before or after.`;

/**
 * Build the analysis prompt from Flutter's posted data.
 */
function buildPrompt(pitchDeck = {}, valuation = {}, comments = {}) {
  return `
Analyze this startup and return a detailed investor report as JSON.

=== PITCH DECK ===
Company: ${pitchDeck.company || 'N/A'}
Sector: ${pitchDeck.sector || 'N/A'}
Funding Goal: ${pitchDeck.fundingGoal || 'N/A'}
Ask Amount: ${pitchDeck.askAmount || 'N/A'}
Business Idea: ${pitchDeck.businessIdea || 'N/A'}
Problem Statement: ${pitchDeck.problemStatement || 'N/A'}
Solution: ${pitchDeck.solution || 'N/A'}
Market Size: ${pitchDeck.marketSize || 'N/A'}
Revenue Model: ${pitchDeck.revenueModel || 'N/A'}
Team Details: ${pitchDeck.teamDetails || 'N/A'}

=== VALUATION ===
Required Funding: ${valuation.requiredFunding || 'N/A'}
Equity Offered: ${valuation.equityOffered || 'N/A'}%
Implied Valuation: ${valuation.impliedValuation || 'N/A'}
Current Revenue: ${valuation.currentRevenue || 'N/A'}
Expenses: ${valuation.expenses || 'N/A'}
Profit Margin: ${valuation.profitMargin || 'N/A'}%
Growth Rate: ${valuation.growthRate || 'N/A'}%

=== FOUNDER & BACKGROUND ===
Business Background: ${comments.businessBackground || 'N/A'}
Founder Experience: ${comments.experience || 'N/A'}
Current Traction: ${comments.traction || 'N/A'}
Stage: ${comments.stage || 'N/A'}
Use of Funds: ${comments.useOfFunds || 'N/A'}
Competitors: ${comments.competitorDetails || 'N/A'}
Risks: ${comments.riskFactors || 'N/A'}
Future Plan: ${comments.futurePlan || 'N/A'}

Return ONLY this JSON structure (no markdown, no extra text):
{
  "verdict": "STRONG INVEST" | "INVEST" | "CONSIDER" | "PASS",
  "summary": "2-3 sentence executive summary",
  "overall_score": 0.0-1.0,
  "pitch_score": 0.0-1.0,
  "valuation_score": 0.0-1.0,
  "team_score": 0.0-1.0,
  "market_score": 0.0-1.0,
  "strengths": ["s1", "s2", "s3"],
  "weaknesses": ["w1", "w2"],
  "opportunities": ["o1", "o2"],
  "recommendations": ["r1", "r2", "r3"],
  "final_recommendation": "3-4 sentence detailed recommendation paragraph"
}
`;
}

/**
 * POST /api/ai/analyze
 */
exports.analyzeStartup = async (req, res) => {
  try {
    const { pitchDeck, valuation, comments } = req.body;

    if (!pitchDeck && !valuation && !comments) {
      return res.status(400).json({ error: 'No data provided for analysis.' });
    }

    const prompt = buildPrompt(pitchDeck, valuation, comments);

    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      temperature: 0.3,
      max_tokens: 2500,
    });

    const rawContent = completion.choices[0]?.message?.content ?? '';

    // Strip any accidental markdown fences
    let jsonStr = rawContent.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
        .replace(/^```[a-z]*\n?/, '')
        .replace(/```$/, '')
        .trim();
    }

    let report;
    try {
      report = JSON.parse(jsonStr);
    } catch (parseErr) {
      console.error('JSON parse error:', parseErr);
      return res.status(500).json({
        error: 'AI returned invalid JSON',
        raw: rawContent,
      });
    }

    return res.status(200).json({
      success: true,
      report,
      generatedAt: new Date().toISOString(),
      model: 'llama3-8b-8192',
    });
  } catch (err) {
    console.error('Groq API error:', err);
    return res.status(500).json({
      error: err.message || 'Internal server error',
    });
  }
};