// lib/models/stratic_model.dart

// ── Shared file slot used by all modules ─────────────────────────────────────
class ModuleFileSlot {
  final String key;
  String? fileName;
  String? fileUrl;
  bool isUploaded;

  ModuleFileSlot({required this.key, this.isUploaded = false});
}

// ═════════════════════════════════════════════════════════════════════════════
// STRATIC
// ═════════════════════════════════════════════════════════════════════════════
class StraticState {
  String? recordId;
  StraticAiReport? aiReport;

  final ModuleFileSlot team        = ModuleFileSlot(key: 'team');
  final ModuleFileSlot businessDev = ModuleFileSlot(key: 'businessDev');
  final ModuleFileSlot risk        = ModuleFileSlot(key: 'risk');
  final ModuleFileSlot operation   = ModuleFileSlot(key: 'operation');
  final ModuleFileSlot policy      = ModuleFileSlot(key: 'policy');
  final ModuleFileSlot challenges  = ModuleFileSlot(key: 'challenges');
  final ModuleFileSlot profile     = ModuleFileSlot(key: 'profile');

  List<ModuleFileSlot> get allSlots => [
    team, businessDev, risk, operation, policy, challenges, profile,
  ];

  int get uploadedCount => allSlots.where((s) => s.isUploaded).length;

  String buildPrompt(Map<String, dynamic> extracted) => '''
You are an expert business strategist. Analyse the following strategic documents and return a JSON object ONLY:

${extracted.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Return this exact JSON:
{
  "verdict": "STRONG" | "MODERATE" | "WEAK",
  "summary": "2-3 sentence summary",
  "overallScore": 0.0-1.0,
  "teamScore": 0.0-1.0,
  "operationScore": 0.0-1.0,
  "policyScore": 0.0-1.0,
  "challengeScore": 0.0-1.0,
  "strengths": ["s1","s2"],
  "risks": ["r1","r2"],
  "opportunities": ["o1","o2"],
  "recommendations": ["rec1","rec2"],
  "finalRecommendation": "Detailed paragraph"
}
''';

  String buildFallbackPrompt() => '''
You are an expert business strategist. No documents uploaded. Return:
{
  "verdict": "INCOMPLETE",
  "summary": "No documents uploaded.",
  "overallScore": 0.3,
  "teamScore": 0.3,
  "operationScore": 0.3,
  "policyScore": 0.3,
  "challengeScore": 0.3,
  "strengths": ["Documentation initiated"],
  "risks": ["Cannot assess without documents"],
  "opportunities": ["Upload all 7 for full analysis"],
  "recommendations": ["Upload team documents"],
  "finalRecommendation": "Upload all documents for a full analysis."
}
''';
}

class StraticAiReport {
  final String       rawJson;
  final String       verdict;
  final String       summary;
  final double       overallScore;
  final double       teamScore;
  final double       operationScore;
  final double       policyScore;
  final double       challengeScore;
  final List<String> strengths;
  final List<String> risks;
  final List<String> opportunities;
  final List<String> recommendations;
  final String       finalRecommendation;

  const StraticAiReport({
    required this.rawJson,
    required this.verdict,
    required this.summary,
    required this.overallScore,
    required this.teamScore,
    required this.operationScore,
    required this.policyScore,
    required this.challengeScore,
    required this.strengths,
    required this.risks,
    required this.opportunities,
    required this.recommendations,
    required this.finalRecommendation,
  });

  factory StraticAiReport.fromJson(String raw, Map<String, dynamic> j) {
    List<String> _l(String k) =>
        (j[k] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return StraticAiReport(
      rawJson:             raw,
      verdict:             j['verdict']          as String? ?? 'UNKNOWN',
      summary:             j['summary']          as String? ?? '',
      overallScore:        (j['overallScore']     as num? ?? 0).toDouble(),
      teamScore:      (j['teamScore']      as num? ?? 0).toDouble(),
      operationScore: (j['operationScore'] as num? ?? 0).toDouble(),
      policyScore:    (j['policyScore']    as num? ?? 0).toDouble(),
      challengeScore: (j['challengeScore'] as num? ?? 0).toDouble(),
      strengths:           _l('strengths'),
      risks:               _l('risks'),
      opportunities:       _l('opportunities'),
      recommendations:     _l('recommendations'),
      finalRecommendation: j['finalRecommendation'] as String? ?? '',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAXATION
// ═════════════════════════════════════════════════════════════════════════════
class TaxationState {
  String? recordId;
  TaxationAiReport? aiReport;

  final ModuleFileSlot businessTaxProfile = ModuleFileSlot(key: 'businessTaxProfile');
  final ModuleFileSlot directTax          = ModuleFileSlot(key: 'directTax');
  final ModuleFileSlot indirectTax        = ModuleFileSlot(key: 'indirectTax');
  final ModuleFileSlot tds                = ModuleFileSlot(key: 'tds');
  final ModuleFileSlot payrollTax         = ModuleFileSlot(key: 'payrollTax');
  final ModuleFileSlot liabilities        = ModuleFileSlot(key: 'liabilities');
  final ModuleFileSlot taxPlanning        = ModuleFileSlot(key: 'taxPlanning');

  List<ModuleFileSlot> get allSlots => [
    businessTaxProfile, directTax, indirectTax,
    tds, payrollTax, liabilities, taxPlanning,
  ];

  int get uploadedCount => allSlots.where((s) => s.isUploaded).length;

  String buildPrompt(Map<String, dynamic> extracted) => '''
You are an expert tax analyst. Analyse the following tax documents and return a JSON object ONLY:

${extracted.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Return this exact JSON:
{
  "verdict": "COMPLIANT" | "PARTIALLY COMPLIANT" | "NON-COMPLIANT",
  "summary": "2-3 sentence summary",
  "overallScore": 0.0-1.0,
  "complianceScore": 0.0-1.0,
  "directTaxScore": 0.0-1.0,
  "indirectTaxScore": 0.0-1.0,
  "planningScore": 0.0-1.0,
  "strengths": ["s1","s2"],
  "risks": ["r1","r2"],
  "opportunities": ["o1","o2"],
  "recommendations": ["rec1","rec2"],
  "finalRecommendation": "Detailed paragraph"
}
''';

  String buildFallbackPrompt() => '''
You are an expert tax analyst. No documents uploaded. Return:
{
  "verdict": "INCOMPLETE — NO DOCUMENTS",
  "summary": "No documents uploaded for analysis.",
  "overallScore": 0.3,
  "complianceScore": 0.3,
  "directTaxScore": 0.3,
  "indirectTaxScore": 0.3,
  "planningScore": 0.3,
  "strengths": ["Documentation initiated"],
  "risks": ["Cannot assess without documents"],
  "opportunities": ["Upload all 7 for full analysis"],
  "recommendations": ["Upload ITR and Form 16"],
  "finalRecommendation": "Upload all documents for a comprehensive tax analysis."
}
''';
}

class TaxationAiReport {
  final String       rawJson;
  final String       verdict;
  final String       summary;
  final double       overallScore;
  final double       complianceScore;
  final double       directTaxScore;
  final double       indirectTaxScore;
  final double       planningScore;
  final List<String> strengths;
  final List<String> risks;
  final List<String> opportunities;
  final List<String> recommendations;
  final String       finalRecommendation;

  const TaxationAiReport({
    required this.rawJson,
    required this.verdict,
    required this.summary,
    required this.overallScore,
    required this.complianceScore,
    required this.directTaxScore,
    required this.indirectTaxScore,
    required this.planningScore,
    required this.strengths,
    required this.risks,
    required this.opportunities,
    required this.recommendations,
    required this.finalRecommendation,
  });

  factory TaxationAiReport.fromJson(String raw, Map<String, dynamic> j) {
    List<String> _l(String k) =>
        (j[k] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return TaxationAiReport(
      rawJson:             raw,
      verdict:             j['verdict']           as String? ?? 'UNKNOWN',
      summary:             j['summary']           as String? ?? '',
      overallScore:        (j['overallScore']      as num? ?? 0).toDouble(),
      complianceScore:     (j['complianceScore']   as num? ?? 0).toDouble(),
      directTaxScore:      (j['directTaxScore']    as num? ?? 0).toDouble(),
      indirectTaxScore:    (j['indirectTaxScore']  as num? ?? 0).toDouble(),
      planningScore:       (j['planningScore']     as num? ?? 0).toDouble(),
      strengths:           _l('strengths'),
      risks:               _l('risks'),
      opportunities:       _l('opportunities'),
      recommendations:     _l('recommendations'),
      finalRecommendation: j['finalRecommendation'] as String? ?? '',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LAND / LEGAL
// ═════════════════════════════════════════════════════════════════════════════
class LandLegalState {
  String? recordId;
  LandLegalAiReport? aiReport;

  final ModuleFileSlot propertyOwnership = ModuleFileSlot(key: 'propertyOwnership');
  final ModuleFileSlot titleDocuments    = ModuleFileSlot(key: 'titleDocuments');
  final ModuleFileSlot zoningCompliance  = ModuleFileSlot(key: 'zoningCompliance');
  final ModuleFileSlot licenses          = ModuleFileSlot(key: 'licenses');
  final ModuleFileSlot contracts         = ModuleFileSlot(key: 'contracts');
  final ModuleFileSlot legalIssues       = ModuleFileSlot(key: 'legalIssues');
  final ModuleFileSlot governance        = ModuleFileSlot(key: 'governance');

  List<ModuleFileSlot> get allSlots => [
    propertyOwnership, titleDocuments, zoningCompliance,
    licenses, contracts, legalIssues, governance,
  ];

  int get uploadedCount => allSlots.where((s) => s.isUploaded).length;

  String buildPrompt(Map<String, dynamic> extracted) => '''
You are an expert legal analyst specialising in property law and compliance.
Analyse the following land/legal documents and return a JSON object ONLY:

${extracted.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Return this exact JSON:
{
  "verdict": "LEGALLY SOUND" | "PARTIALLY COMPLIANT" | "LEGAL RISKS IDENTIFIED",
  "summary": "2-3 sentence summary",
  "overallScore": 0.0-1.0,
  "ownershipScore": 0.0-1.0,
  "complianceScore": 0.0-1.0,
  "contractScore": 0.0-1.0,
  "governanceScore": 0.0-1.0,
  "strengths": ["s1","s2"],
  "risks": ["r1","r2"],
  "opportunities": ["o1","o2"],
  "recommendations": ["rec1","rec2"],
  "finalRecommendation": "Detailed paragraph"
}
''';

  String buildFallbackPrompt() => '''
You are an expert legal analyst. No documents uploaded. Return:
{
  "verdict": "INCOMPLETE — NO DOCUMENTS",
  "summary": "No documents uploaded for analysis.",
  "overallScore": 0.3,
  "ownershipScore": 0.3,
  "complianceScore": 0.3,
  "contractScore": 0.3,
  "governanceScore": 0.3,
  "strengths": ["Documentation initiated"],
  "risks": ["Cannot assess without documents"],
  "opportunities": ["Upload all 7 for full analysis"],
  "recommendations": ["Upload property ownership documents"],
  "finalRecommendation": "Upload all documents for a comprehensive legal analysis."
}
''';
}

class LandLegalAiReport {
  final String       rawJson;
  final String       verdict;
  final String       summary;
  final double       overallScore;
  final double       ownershipScore;
  final double       complianceScore;
  final double       contractScore;
  final double       governanceScore;
  final List<String> strengths;
  final List<String> risks;
  final List<String> opportunities;
  final List<String> recommendations;
  final String       finalRecommendation;

  const LandLegalAiReport({
    required this.rawJson,
    required this.verdict,
    required this.summary,
    required this.overallScore,
    required this.ownershipScore,
    required this.complianceScore,
    required this.contractScore,
    required this.governanceScore,
    required this.strengths,
    required this.risks,
    required this.opportunities,
    required this.recommendations,
    required this.finalRecommendation,
  });

  factory LandLegalAiReport.fromJson(String raw, Map<String, dynamic> j) {
    List<String> _l(String k) =>
        (j[k] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return LandLegalAiReport(
      rawJson:             raw,
      verdict:             j['verdict']            as String? ?? 'UNKNOWN',
      summary:             j['summary']            as String? ?? '',
      overallScore:        (j['overallScore']       as num? ?? 0).toDouble(),
      ownershipScore:      (j['ownershipScore']     as num? ?? 0).toDouble(),
      complianceScore:     (j['complianceScore']    as num? ?? 0).toDouble(),
      contractScore:       (j['contractScore']      as num? ?? 0).toDouble(),
      governanceScore:     (j['governanceScore']    as num? ?? 0).toDouble(),
      strengths:           _l('strengths'),
      risks:               _l('risks'),
      opportunities:       _l('opportunities'),
      recommendations:     _l('recommendations'),
      finalRecommendation: j['finalRecommendation'] as String? ?? '',
    );
  }
}