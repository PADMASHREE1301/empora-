// lib/models/fund_raising_model.dart

// ─── Pitch Deck Data ──────────────────────────────────────────────────────────
class PitchDeckData {
  String company          = '';
  String fundingGoal      = '';
  String sector           = '';
  String businessIdea     = '';
  String problemStatement = '';
  String solution         = '';
  String marketSize       = '';
  String revenueModel     = '';
  String teamDetails      = '';
  String askAmount        = '';

  String? fileUrl;
  String? fileName;

  bool isProblemDone    = false;
  bool isSolutionDone   = false;
  bool isMarketDone     = false;
  bool isModelDone      = false;
  bool isTractionDone   = false;
  bool isTeamDone       = false;
  bool isFinancialsDone = false;
  bool isAskDone        = false;

  int get completedSections =>
      [isProblemDone, isSolutionDone, isMarketDone, isModelDone,
       isTractionDone, isTeamDone, isFinancialsDone, isAskDone]
          .where((e) => e).length;

  double get completionPercent => completedSections / 8;

  bool get isReady =>
      company.isNotEmpty &&
      sector.isNotEmpty &&
      businessIdea.isNotEmpty &&
      problemStatement.isNotEmpty &&
      solution.isNotEmpty;

  String toPromptText() => '''
=== PITCH DECK (Form Fields) ===
Company: $company
Sector: $sector
Funding Goal: $fundingGoal
Ask Amount: $askAmount
Business Idea: $businessIdea
Problem Statement: $problemStatement
Solution: $solution
Market Size: $marketSize
Revenue Model: $revenueModel
Team Details: $teamDetails
''';
}

// ─── Valuation Data ───────────────────────────────────────────────────────────
class ValuationData {
  String requiredFunding  = '';
  String equityOffered    = '';
  String currentRevenue   = '';
  String expenses         = '';
  String profitMargin     = '';
  String growthRate       = '';
  String impliedValuation = '';

  String? fileUrl;
  String? fileName;

  bool get isReady =>
      requiredFunding.isNotEmpty && equityOffered.isNotEmpty;

  String toPromptText() => '''
=== VALUATION (Form Fields) ===
Required Funding: $requiredFunding
Equity Offered: $equityOffered%
Implied Valuation: $impliedValuation
Current Revenue: $currentRevenue
Expenses: $expenses
Profit Margin: $profitMargin%
Growth Rate: $growthRate%
''';
}

// ─── Comments Data ────────────────────────────────────────────────────────────
class CommentsData {
  String businessBackground = '';
  String experience         = '';
  String competitorDetails  = '';
  String riskFactors        = '';
  String futurePlan         = '';
  String useOfFunds         = '';
  String traction           = '';
  String fundingStage       = 'Seed';
  bool   isComplete         = false;

  List<InvestorComment> investorComments = [];
  List<FounderModel>    founders = [FounderModel(name: '', role: '', linkedin: '')];

  bool get isReady => businessBackground.isNotEmpty;

  String toPromptText() => '''
=== FOUNDER & BACKGROUND (Form Fields) ===
Business Background: $businessBackground
Founder Experience: $experience
Current Traction: $traction
Stage: $fundingStage
Use of Funds: $useOfFunds
Competitor Details: $competitorDetails
Risk Factors: $riskFactors
Future Plan: $futurePlan

Investor Comments:
${investorComments.isNotEmpty ? investorComments.map((c) => '- ${c.text}').join('\n') : 'None'}
''';
}

// ─── Supporting models ────────────────────────────────────────────────────────
class InvestorComment {
  final String name;
  final String avatar;
  final String time;
  final String text;
  final bool   isOwn;

  InvestorComment({
    required this.name,
    required this.avatar,
    required this.time,
    required this.text,
    required this.isOwn,
  });
}

class FounderModel {
  String name;
  String role;
  String linkedin;
  FounderModel({required this.name, required this.role, required this.linkedin});
}

// ─── AI Report Data ───────────────────────────────────────────────────────────
class AiReportData {
  final String rawText;
  final String verdict;
  final String summary;
  final double overallScore;
  final double pitchScore;
  final double valuationScore;
  final double teamScore;
  final double marketScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> opportunities;
  final List<String> recommendations;
  final String recommendation;
  final DateTime generatedAt;

  AiReportData({
    required this.rawText,
    required this.verdict,
    required this.summary,
    required this.overallScore,
    required this.pitchScore,
    required this.valuationScore,
    required this.teamScore,
    required this.marketScore,
    required this.strengths,
    required this.weaknesses,
    required this.opportunities,
    required this.recommendations,
    required this.recommendation,
    required this.generatedAt,
  });

  factory AiReportData.fromGroqResponse(
      String rawText, Map<String, dynamic> json) {
    double d(dynamic v, double def) {
      if (v == null) return def;
      final n = double.tryParse(v.toString());
      return (n == null) ? def : (n > 1 ? n / 100 : n);
    }

    List<String> lst(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [v.toString()];
    }

    return AiReportData(
      rawText:         rawText,
      verdict:         json['verdict']?.toString() ?? 'CONSIDER',
      summary:         json['summary']?.toString() ?? '',
      overallScore:    d(json['overall_score'], 0.5),
      pitchScore:      d(json['pitch_score'], 0.5),
      valuationScore:  d(json['valuation_score'], 0.5),
      teamScore:       d(json['team_score'], 0.5),
      marketScore:     d(json['market_score'], 0.5),
      strengths:       lst(json['strengths']),
      weaknesses:      lst(json['weaknesses']),
      opportunities:   lst(json['opportunities']),
      recommendations: lst(json['recommendations']),
      recommendation:  json['final_recommendation']?.toString() ?? '',
      generatedAt:     DateTime.now(),
    );
  }
}

// ─── Shared State ─────────────────────────────────────────────────────────────
class FundRaisingState {
  String? recordId;

  final PitchDeckData pitchDeck = PitchDeckData();
  final ValuationData valuation = ValuationData();
  final CommentsData  comments  = CommentsData();
  AiReportData? aiReport;

  bool get isPitchReady     => pitchDeck.isReady;
  bool get isValuationReady => valuation.isReady;
  bool get isCommentsReady  => comments.isReady;

  int get readinessPercent {
    int count = 0;
    if (isPitchReady)     count++;
    if (isValuationReady) count++;
    if (isCommentsReady)  count++;
    if (aiReport != null) count++;
    return ((count / 4) * 100).round();
  }

  // ─── Fallback prompt (form fields only) ───────────────────────────────────
  // Used when recordId is null or getExtractedText() fails.
  String buildPrompt() => '''
You are an expert startup investor analyst. Analyze this startup and return a detailed investor report.

${pitchDeck.toPromptText()}
${valuation.toPromptText()}
${comments.toPromptText()}

Return ONLY valid JSON (no markdown, no extra text):
{
  "verdict": "STRONG INVEST" | "INVEST" | "CONSIDER" | "PASS",
  "summary": "2-3 sentence executive summary",
  "overall_score": 0.0-1.0,
  "pitch_score": 0.0-1.0,
  "valuation_score": 0.0-1.0,
  "team_score": 0.0-1.0,
  "market_score": 0.0-1.0,
  "strengths": ["strength1", "strength2", "strength3"],
  "weaknesses": ["weakness1", "weakness2"],
  "opportunities": ["opportunity1", "opportunity2"],
  "recommendations": ["action1", "action2", "action3"],
  "final_recommendation": "3-4 sentence detailed paragraph"
}
''';

  // ─── NEW: Rich prompt using ACTUAL file content from backend ──────────────
  // [extracted] is the Map returned by ApiService.getExtractedText().
  // Contains: pitchDeckText, valuationText, commentsText,
  //           pitchDeckFields, valuationFields, commentsFields
  String buildPromptWithExtractedText(Map<String, dynamic> extracted) {
    final pitchFileText  = (extracted['pitchDeckText'] as String? ?? '').trim();
    final valuationText  = (extracted['valuationText'] as String? ?? '').trim();
    final commentsText   = (extracted['commentsText']  as String? ?? '').trim();

    final pf = (extracted['pitchDeckFields']  as Map?)?.cast<String, dynamic>() ?? {};
    final vf = (extracted['valuationFields']  as Map?)?.cast<String, dynamic>() ?? {};
    final cf = (extracted['commentsFields']   as Map?)?.cast<String, dynamic>() ?? {};

    // ── Pitch section ── prefer actual file text, fall back to form fields ──
    final pitchSection = pitchFileText.isNotEmpty
        ? '''
=== PITCH DECK (Extracted from uploaded file) ===
$pitchFileText
'''
        : '''
=== PITCH DECK (Form Data) ===
Company: ${pf['company'] ?? pitchDeck.company}
Sector: ${pf['sector'] ?? pitchDeck.sector}
Funding Goal: ${pf['fundingGoal'] ?? pitchDeck.fundingGoal}
Ask Amount: ${pf['askAmount'] ?? pitchDeck.askAmount}
Business Idea: ${pf['businessIdea'] ?? pitchDeck.businessIdea}
Problem Statement: ${pf['problemStatement'] ?? pitchDeck.problemStatement}
Solution: ${pf['solution'] ?? pitchDeck.solution}
Market Size: ${pf['marketSize'] ?? pitchDeck.marketSize}
Revenue Model: ${pf['revenueModel'] ?? pitchDeck.revenueModel}
Team Details: ${pf['teamDetails'] ?? pitchDeck.teamDetails}
''';

    // ── Valuation section ─────────────────────────────────────────────────────
    final valuationSection = valuationText.isNotEmpty
        ? '''
=== VALUATION (Extracted from uploaded file) ===
$valuationText
'''
        : '''
=== VALUATION (Form Data) ===
Required Funding: ${vf['requiredFunding'] ?? valuation.requiredFunding}
Equity Offered: ${vf['equityOffered'] ?? valuation.equityOffered}%
Implied Valuation: ${vf['impliedValuation'] ?? valuation.impliedValuation}
Current Revenue: ${vf['currentRevenue'] ?? valuation.currentRevenue}
Expenses: ${vf['expenses'] ?? valuation.expenses}
Profit Margin: ${vf['profitMargin'] ?? valuation.profitMargin}%
Growth Rate: ${vf['growthRate'] ?? valuation.growthRate}%
''';

    // ── Comments section ──────────────────────────────────────────────────────
    final commentsSection = commentsText.isNotEmpty
        ? '''
=== BUSINESS BACKGROUND (Extracted from uploaded file) ===
$commentsText
'''
        : '''
=== BUSINESS BACKGROUND (Form Data) ===
Background: ${cf['businessBackground'] ?? comments.businessBackground}
Experience: ${cf['experience'] ?? comments.experience}
Traction: ${cf['traction'] ?? comments.traction}
Stage: ${cf['stage'] ?? comments.fundingStage}
Use of Funds: ${cf['useOfFunds'] ?? comments.useOfFunds}
Competitors: ${cf['competitorDetails'] ?? comments.competitorDetails}
Risks: ${cf['riskFactors'] ?? comments.riskFactors}
Future Plan: ${cf['futurePlan'] ?? comments.futurePlan}
''';

    return '''
You are an expert startup investor analyst.
Carefully read ALL the documents below and generate a thorough, specific investor analysis.

$pitchSection

$valuationSection

$commentsSection

Based on the actual document content above, return ONLY valid JSON (no markdown, no extra text):
{
  "verdict": "STRONG INVEST" | "INVEST" | "CONSIDER" | "PASS",
  "summary": "2-3 sentence executive summary referencing actual content from the documents",
  "overall_score": 0.0-1.0,
  "pitch_score": 0.0-1.0,
  "valuation_score": 0.0-1.0,
  "team_score": 0.0-1.0,
  "market_score": 0.0-1.0,
  "strengths": ["specific strength from documents", "specific strength", "specific strength"],
  "weaknesses": ["specific weakness from documents", "specific weakness"],
  "opportunities": ["specific opportunity from documents", "specific opportunity"],
  "recommendations": ["specific actionable recommendation", "recommendation", "recommendation"],
  "final_recommendation": "3-4 sentence paragraph with specific references to the documents"
}
''';
  }

  // ─── Offline fallback ──────────────────────────────────────────────────────
  // Used when Groq API fails. Scores are based on BOTH form fields AND
  // file presence — so uploading files always gives meaningful scores.
  AiReportData generateReport() {
    final pd = pitchDeck;
    final vd = valuation;
    final cd = comments;

    final hasPitchFile    = pd.fileUrl != null;
    final hasValuationFile = vd.fileUrl != null;

    // ── Score calculation ─────────────────────────────────────────────────────
    // Form-field score (max 0.70)
    double formScore = 0.0;
    if (pd.company.isNotEmpty)            formScore += 0.10;
    if (pd.businessIdea.isNotEmpty)       formScore += 0.10;
    if (pd.solution.isNotEmpty)           formScore += 0.08;
    if (vd.requiredFunding.isNotEmpty)    formScore += 0.10;
    if (vd.equityOffered.isNotEmpty)      formScore += 0.08;
    if (cd.businessBackground.isNotEmpty) formScore += 0.10;
    if (cd.experience.isNotEmpty)         formScore += 0.08;
    formScore += pd.completionPercent * 0.06;

    // File-upload bonus (max 0.30) — reward users who upload documents
    double fileScore = 0.0;
    if (hasPitchFile)     fileScore += 0.15;
    if (hasValuationFile) fileScore += 0.10;
    if (cd.isComplete)    fileScore += 0.05;

    final score = (formScore + fileScore).clamp(0.0, 1.0);

    // ── Sub-scores ────────────────────────────────────────────────────────────
    final pitchScore = hasPitchFile
        ? (0.55 + pd.completionPercent * 0.30).clamp(0.0, 1.0)
        : (pd.completionPercent * 0.85 + 0.1).clamp(0.0, 1.0);

    final valuationScore = hasValuationFile
        ? 0.60
        : (vd.isReady ? 0.55 : 0.30);

    final teamScore = cd.experience.isNotEmpty
        ? 0.72
        : (hasPitchFile ? 0.50 : 0.45);

    final marketScore = pd.marketSize.isNotEmpty
        ? 0.68
        : (hasPitchFile ? 0.52 : 0.40);

    final verdict = score > 0.75 ? 'STRONG INVEST'
        : score > 0.55 ? 'INVEST'
        : score > 0.35 ? 'CONSIDER' : 'PASS';

    // ── Dynamic summary using available data ──────────────────────────────────
    final companyName = pd.company.isNotEmpty ? pd.company : 'This startup';
    final sectorName  = pd.sector.isNotEmpty  ? pd.sector  : 'technology';
    final fundingStr  = pd.fundingGoal.isNotEmpty ? pd.fundingGoal : 'undisclosed amount';

    final summaryParts = <String>[
      '$companyName is a $sectorName startup seeking $fundingStr in funding.',
      if (hasPitchFile && hasValuationFile)
        'Complete pitch deck and valuation documents have been uploaded for analysis.'
      else if (hasPitchFile)
        'A pitch deck document has been uploaded and reviewed.'
      else
        'Limited documentation provided — uploading full documents will improve analysis accuracy.',
      if (score > 0.55)
        'Initial assessment indicates investment potential subject to further due diligence.'
      else
        'The startup requires additional preparation before investor presentation.',
    ];

    return AiReportData(
      rawText:         '(Estimated report)',
      verdict:         verdict,
      summary:         summaryParts.join(' '),
      overallScore:    score,
      pitchScore:      pitchScore,
      valuationScore:  valuationScore,
      teamScore:       teamScore,
      marketScore:     marketScore,
      strengths: [
        if (hasPitchFile)                  'Pitch deck document submitted and reviewed',
        if (hasValuationFile)              'Valuation model and financial projections provided',
        if (pd.solution.isNotEmpty)        'Clear solution articulation for the identified problem',
        if (vd.requiredFunding.isNotEmpty) 'Defined capital requirements and funding ask',
        if (cd.traction.isNotEmpty)        'Early traction and market validation demonstrated',
        if (pd.marketSize.isNotEmpty)      'Market size and opportunity clearly identified',
        if (cd.experience.isNotEmpty)      'Founding team experience and background documented',
        if (pd.revenueModel.isNotEmpty)    'Revenue model and monetization strategy defined',
      ],
      weaknesses: [
        if (!hasPitchFile)                 'Pitch deck not uploaded — detailed deck review pending',
        if (!hasValuationFile)             'Financial model not uploaded — valuation assessment limited',
        if (pd.problemStatement.isEmpty)   'Problem statement lacks sufficient detail and context',
        if (cd.competitorDetails.isEmpty)  'Competitive landscape and differentiation not addressed',
        if (vd.equityOffered.isEmpty)      'Equity structure and cap table not yet defined',
        if (cd.riskFactors.isEmpty)        'Risk factors and mitigation strategies not documented',
      ],
      opportunities: [
        if (pd.sector.isNotEmpty) '${pd.sector} sector presents strong growth tailwinds',
        'Strategic partnerships can accelerate customer acquisition',
        'Technology-driven automation reduces operational costs at scale',
        if (cd.futurePlan.isNotEmpty) 'Clear product roadmap indicates long-term vision',
        'Expansion into adjacent markets post product-market fit',
        'Data network effects can create sustainable competitive moat',
      ],
      recommendations: [
        if (!hasPitchFile || !hasValuationFile)
          'Upload complete pitch deck and financial model for comprehensive analysis',
        'Develop detailed 5-year financial projections with monthly burn rate and runway',
        'Include specific go-to-market milestones with measurable KPIs and timelines',
        'Strengthen competitive analysis with clear differentiation and defensibility',
        if (cd.riskFactors.isEmpty)
          'Document key risk factors and concrete mitigation strategies',
        'Add customer testimonials, case studies, or pilot results to validate traction',
      ],
      recommendation:
          '$companyName ${score > 0.65 ? "demonstrates strong investment potential" : score > 0.45 ? "shows moderate investment potential with key areas to strengthen" : "requires additional preparation before investor presentation"}. '
          '${hasPitchFile && hasValuationFile ? "Both pitch deck and valuation documents have been submitted for review. " : ""}'
          'Priority focus areas include refining the competitive positioning, '
          'strengthening financial projections, and clearly articulating the go-to-market strategy. '
          'A follow-up discussion with the founding team is recommended to validate traction metrics and unit economics.',
      generatedAt: DateTime.now(),
    );
  }
}