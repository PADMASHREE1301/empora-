// routes/stratic.js  ─── ADD THIS ROUTE to your existing stratic router
// Route: POST /api/stratic/:id/generate-ai
// This runs the AI analysis SERVER-SIDE so the API key never touches the mobile app.

const axios = require('axios');

// ── Helper: extract text from all uploaded slots ───────────────────────────
function buildExtractedText(record) {
  // Your MongoDB stratic document should have an 'extracted' or 'files' field
  // containing the text extracted from each uploaded .docx file.
  // Adjust the field names below to match your actual schema.
  const extracted = record.extracted || record.files || {};
  return extracted;
}

// ── Helper: build the AI prompt ────────────────────────────────────────────
function buildPrompt(extracted) {
  const moduleLabels = {
    team:        'TEAM PROFILE',
    businessDev: 'BUSINESS DEVELOPMENT',
    risk:        'RISK OVERVIEW',
    operation:   'OPERATIONS',
    policy:      'POLICY',
    challenges:  'CHALLENGES',
    profile:     'COMPANY PROFILE',
  };

  let docSection = '';
  let hasContent = false;

  for (const [key, value] of Object.entries(extracted)) {
    const label   = moduleLabels[key] || key.toUpperCase();
    const content = (typeof value === 'object' ? value?.extractedText || value?.text || value?.content || '' : String(value || '')).trim();
    if (content) {
      // Cap each document at 1500 chars to stay within token limits
      docSection += `=== ${label} ===\n${content.substring(0, 1500)}${content.length > 1500 ? '...' : ''}\n\n`;
      hasContent = true;
    }
  }

  if (!hasContent) {
    docSection = '[No document text could be extracted. Provide general strategic guidance.]\n';
  }

  return `You are a senior business strategist with 20+ years of experience.
Analyse the following strategy documents and produce a comprehensive report.
Base your analysis STRICTLY on the actual content provided below.

${docSection}
Return ONLY this valid JSON (no markdown fences, no preamble):
{
  "verdict": "STRONG" | "MODERATE" | "WEAK",
  "summary": "3-4 sentence executive summary referencing specific content from the documents",
  "overallScore": 0.0-1.0,
  "teamScore": 0.0-1.0,
  "operationScore": 0.0-1.0,
  "policyScore": 0.0-1.0,
  "challengeScore": 0.0-1.0,
  "strengths": ["Specific strength from documents","Specific strength 2","Specific strength 3"],
  "risks": ["Specific risk from documents","Specific risk 2","Specific risk 3"],
  "opportunities": ["Opportunity from documents","Opportunity 2","Opportunity 3"],
  "recommendations": ["Actionable recommendation 1","Recommendation 2","Recommendation 3"],
  "finalRecommendation": "3-4 sentence paragraph with specific, actionable next steps from the documents."
}

CRITICAL: Never output placeholder text like 'Documents uploaded', 'retry', or 'API key'.
All content must reference actual information from the submitted documents.`;
}

// ── Helper: call Groq API ──────────────────────────────────────────────────
async function callGroq(prompt) {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY not set in server environment');

  const response = await axios.post(
    'https://api.groq.com/openai/v1/chat/completions',
    {
      model: 'mixtral-8x7b-32768',
      messages: [
        {
          role: 'system',
          content: 'You are a senior business strategist. Respond ONLY with valid JSON. No markdown, no preamble. Your full response must be parseable by JSON.parse().',
        },
        { role: 'user', content: prompt },
      ],
      temperature: 0.2,
      max_tokens: 2000,
    },
    {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      timeout: 90000,
    }
  );

  return response.data?.choices?.[0]?.message?.content || '';
}

// ── Helper: call Anthropic API (fallback) ─────────────────────────────────
async function callAnthropic(prompt) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY not set in server environment');

  const response = await axios.post(
    'https://api.anthropic.com/v1/messages',
    {
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2000,
      system: 'You are a senior business strategist. Respond ONLY with valid JSON. No markdown, no preamble.',
      messages: [{ role: 'user', content: prompt }],
    },
    {
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      timeout: 90000,
    }
  );

  return response.data?.content?.[0]?.text || '';
}

// ── Helper: parse and validate JSON response ──────────────────────────────
function parseAiResponse(raw) {
  let text = raw.trim();
  // Strip markdown fences if present
  text = text.replace(/^```[a-z]*\n?/, '').replace(/```$/, '').trim();
  return JSON.parse(text);
}

// ══════════════════════════════════════════════════════════════════════════
// ROUTE HANDLER
// Add to your router: router.post('/:id/generate-ai', auth, generateAiReport);
// ══════════════════════════════════════════════════════════════════════════
async function generateAiReport(req, res) {
  try {
    const { id } = req.params;

    // 1. Fetch the stratic record from MongoDB
    //    Replace 'Stratic' with your actual Mongoose model name
    const Stratic = require('../models/Stratic'); // adjust path as needed
    const record = await Stratic.findById(id);

    if (!record) {
      return res.status(404).json({ success: false, message: 'Record not found' });
    }

    // 2. Build prompt from extracted document text
    const extracted = buildExtractedText(record);
    const prompt    = buildPrompt(extracted);

    // 3. Call AI — try Groq first, then Anthropic as fallback
    let rawResponse;
    try {
      rawResponse = await callGroq(prompt);
    } catch (groqErr) {
      console.warn('Groq failed, trying Anthropic:', groqErr.message);
      rawResponse = await callAnthropic(prompt);
    }

    // 4. Parse JSON response
    let aiData;
    try {
      aiData = parseAiResponse(rawResponse);
    } catch (parseErr) {
      console.error('AI JSON parse failed:', rawResponse.substring(0, 200));
      return res.status(500).json({
        success: false,
        message: 'AI returned an invalid response format. Please retry.',
      });
    }

    // 5. Save to MongoDB
    record.aiReport = {
      verdict:             aiData.verdict             || 'MODERATE',
      summary:             aiData.summary             || '',
      overallScore:        aiData.overallScore        || 0.5,
      teamScore:           aiData.teamScore           || 0.5,
      operationScore:      aiData.operationScore      || 0.5,
      policyScore:         aiData.policyScore         || 0.5,
      challengeScore:      aiData.challengeScore      || 0.5,
      strengths:           aiData.strengths           || [],
      risks:               aiData.risks               || [],
      opportunities:       aiData.opportunities       || [],
      recommendations:     aiData.recommendations     || [],
      finalRecommendation: aiData.finalRecommendation || '',
      generatedAt:         new Date(),
    };
    await record.save();

    // 6. Return the report to Flutter
    return res.json({
      success: true,
      data: { aiReport: record.aiReport },
    });

  } catch (err) {
    console.error('generate-ai error:', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Internal server error',
    });
  }
}

module.exports = { generateAiReport };

// ── HOW TO REGISTER THIS ROUTE ─────────────────────────────────────────────
// In your stratic router file (e.g. routes/stratic.js), add:
//
//   const { generateAiReport } = require('./stratic_generate_ai_route');
//   router.post('/:id/generate-ai', authMiddleware, generateAiReport);
//
// Make sure your .env file has:
//   GROQ_API_KEY=your_groq_key_here
//   ANTHROPIC_API_KEY=your_anthropic_key_here  (optional fallback)
