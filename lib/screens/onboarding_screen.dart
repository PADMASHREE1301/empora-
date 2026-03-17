import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _saving = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Page 1 — Location (phone/company already collected in registration)
  final _cityCtrl = TextEditingController();
  String? _state;

  // ── Page 2 — Business
  final _bizNameCtrl  = TextEditingController();
  String? _bizType;
  final _industryCtrl = TextEditingController();
  String? _bizStage;
  String? _teamSize;

  // ── Page 3 — Financials
  String? _annualRevenue;
  String? _fundingStage;
  final _yearCtrl = TextEditingController();

  // ── Page 4 — Goals & Challenges
  final _goalCtrl = TextEditingController();
  final List<String> _allChallenges = [
    'Getting customers', 'Raising funds', 'Managing cash flow',
    'Tax & compliance', 'Hiring & team', 'Legal & contracts',
    'Technology', 'Scaling operations', 'Market competition', 'Loan & debt management',
  ];
  final Set<String> _selectedChallenges = {};

  static const _pageIcons = [
    Icons.location_on_outlined, Icons.business_center_outlined,
    Icons.analytics_outlined, Icons.flag_outlined,
  ];
  static const _pageColors = [
    Color(0xFF1A3A6B), Color(0xFF0D47A1),
    Color(0xFF1565C0), Color(0xFF1976D2),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    _cityCtrl.dispose();
    _bizNameCtrl.dispose();
    _industryCtrl.dispose();
    _goalCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _fadeCtrl.reset();
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      _fadeCtrl.forward();
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _fadeCtrl.reset();
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      _fadeCtrl.forward();
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ApiService.saveFounderProfile({
        'city':          _cityCtrl.text.trim(),
        'state':         _state,
        'businessName':  _bizNameCtrl.text.trim(),
        'businessType':  _bizType,
        'industry':      _industryCtrl.text.trim(),
        'businessStage': _bizStage,
        'teamSize':      _teamSize,
        'annualRevenue': _annualRevenue,
        'fundingStage':  _fundingStage,
        'yearFounded':   int.tryParse(_yearCtrl.text.trim()),
        'primaryGoal':   _goalCtrl.text.trim(),
        'challenges':    _selectedChallenges.toList(),
      });
      await context.read<AuthProvider>().fetchProfile();
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pageColor = _pageColors[_currentPage];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(pageColor),
            _buildStepIndicator(pageColor),
            const SizedBox(height: 8),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _Page1Location(cityCtrl: _cityCtrl, state: _state, onStateChanged: (v) => setState(() => _state = v)),
                    _Page2Business(
                      bizNameCtrl: _bizNameCtrl, industryCtrl: _industryCtrl,
                      bizType: _bizType, bizStage: _bizStage, teamSize: _teamSize,
                      onBizTypeChanged:  (v) => setState(() => _bizType  = v),
                      onBizStageChanged: (v) => setState(() => _bizStage = v),
                      onTeamSizeChanged: (v) => setState(() => _teamSize = v),
                    ),
                    _Page3Financials(
                      yearCtrl: _yearCtrl, annualRevenue: _annualRevenue, fundingStage: _fundingStage,
                      onRevenueChanged: (v) => setState(() => _annualRevenue = v),
                      onFundingChanged: (v) => setState(() => _fundingStage  = v),
                    ),
                    _Page4Goals(
                      goalCtrl: _goalCtrl, allChallenges: _allChallenges,
                      selectedChallenges: _selectedChallenges,
                      onChallengeToggled: (c) => setState(() {
                        if (_selectedChallenges.contains(c)) _selectedChallenges.remove(c);
                        else if (_selectedChallenges.length < 3) _selectedChallenges.add(c);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNav(pageColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color pageColor) {
    final titles    = ['Your Location', 'Your Business', 'Financials', 'Your Goals'];
    final subtitles = ['Where are you operating from?', 'Tell us about your venture', 'Help us tailor financial advice', 'What do you want to achieve?'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
              child: Center(child: Text('E', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: pageColor))),
            ),
            const SizedBox(width: 8),
            Text('EMPORA', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
          ]),
          TextButton(
            onPressed: _skip,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Skip', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(_pageIcons[_currentPage], color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Step ${_currentPage + 1} of 4', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            Text(titles[_currentPage], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ])),
        ]),
        const SizedBox(height: 6),
        Text(subtitles[_currentPage], style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 13)),
      ]),
    );
  }

  Widget _buildStepIndicator(Color pageColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(4, (i) {
          final done   = i < _currentPage;
          final active = i == _currentPage;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              height: 5,
              decoration: BoxDecoration(
                color: done || active ? pageColor : const Color(0xFFE8EAF0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav(Color pageColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        if (_currentPage > 0) ...[
          GestureDetector(
            onTap: _back,
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAF0), width: 1.5), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: pageColor),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GestureDetector(
            onTap: _saving ? null : _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: _saving ? pageColor.withOpacity(0.6) : pageColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: pageColor.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_currentPage == 3 ? 'Complete Setup' : 'Continue',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(width: 8),
                        Icon(_currentPage == 3 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// PAGE 1 — Location Only
class _Page1Location extends StatelessWidget {
  final TextEditingController cityCtrl;
  final String? state;
  final ValueChanged<String?> onStateChanged;
  const _Page1Location({required this.cityCtrl, required this.state, required this.onStateChanged});

  static const _states = [
    'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat',
    'Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh',
    'Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab',
    'Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh',
    'Uttarakhand','West Bengal','Delhi','Chandigarh','Puducherry','Other',
  ];

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1A3A6B);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InfoBanner(
          icon: Icons.check_circle_outline_rounded,
          text: 'Your name, phone and company are already saved from registration. Just tell us your location!',
          color: color,
        ),
        const SizedBox(height: 24),
        _Label('City'),
        const SizedBox(height: 8),
        _InputField(controller: cityCtrl, hint: 'e.g. Chennai, Mumbai, Bangalore', icon: Icons.location_city_outlined, color: color),
        const SizedBox(height: 20),
        _Label('State'),
        const SizedBox(height: 8),
        _DropdownField(hint: 'Select your state', value: state, items: _states, icon: Icons.map_outlined, color: color, onChanged: onStateChanged),
      ]),
    );
  }
}

// PAGE 2 — Business Info
class _Page2Business extends StatelessWidget {
  final TextEditingController bizNameCtrl;
  final TextEditingController industryCtrl;
  final String? bizType, bizStage, teamSize;
  final ValueChanged<String?> onBizTypeChanged, onBizStageChanged, onTeamSizeChanged;

  const _Page2Business({
    required this.bizNameCtrl, required this.industryCtrl,
    required this.bizType, required this.bizStage, required this.teamSize,
    required this.onBizTypeChanged, required this.onBizStageChanged, required this.onTeamSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0D47A1);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('Business / Startup Name'),
        const SizedBox(height: 8),
        _InputField(controller: bizNameCtrl, hint: 'e.g. Acme Technologies', icon: Icons.business_outlined, color: color),
        const SizedBox(height: 20),
        _Label('Industry / Sector'),
        const SizedBox(height: 8),
        _InputField(controller: industryCtrl, hint: 'e.g. Fintech, Retail, Healthcare', icon: Icons.category_outlined, color: color),
        const SizedBox(height: 20),
        _Label('Business Structure'),
        const SizedBox(height: 8),
        _DropdownField(
          hint: 'Select structure', value: bizType,
          items: const ['sole_proprietor','partnership','llp','pvt_ltd','opc','other'],
          displayItems: const ['Sole Proprietor','Partnership','LLP','Pvt Ltd','OPC','Other'],
          icon: Icons.account_balance_outlined, color: color, onChanged: onBizTypeChanged,
        ),
        const SizedBox(height: 20),
        _Label('Business Stage'),
        const SizedBox(height: 10),
        _ChipRow(
          options: const ['idea','mvp','early_revenue','scaling','established'],
          displayOptions: const ['Idea','MVP','Early Revenue','Scaling','Established'],
          selected: bizStage, color: color, onSelected: onBizStageChanged,
        ),
        const SizedBox(height: 20),
        _Label('Team Size'),
        const SizedBox(height: 10),
        _ChipRow(
          options: const ['solo','2-5','6-10','11-50','50+'],
          displayOptions: const ['Solo','2–5','6–10','11–50','50+'],
          selected: teamSize, color: color, onSelected: onTeamSizeChanged,
        ),
      ]),
    );
  }
}

// PAGE 3 — Financials
class _Page3Financials extends StatelessWidget {
  final TextEditingController yearCtrl;
  final String? annualRevenue, fundingStage;
  final ValueChanged<String?> onRevenueChanged, onFundingChanged;

  const _Page3Financials({
    required this.yearCtrl, required this.annualRevenue, required this.fundingStage,
    required this.onRevenueChanged, required this.onFundingChanged,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1565C0);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('Year Founded'),
        const SizedBox(height: 8),
        _InputField(controller: yearCtrl, hint: 'e.g. 2021', icon: Icons.calendar_today_outlined, color: color,
            keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 24),
        _Label('Annual Revenue'),
        const SizedBox(height: 10),
        _ChipRow(
          options: const ['pre_revenue','under_10l','10l_50l','50l_1cr','1cr_5cr','5cr+'],
          displayOptions: const ['Pre-revenue','< ₹10L','₹10L–50L','₹50L–1Cr','₹1Cr–5Cr','₹5Cr+'],
          selected: annualRevenue, color: color, onSelected: onRevenueChanged,
        ),
        const SizedBox(height: 24),
        _Label('Funding Stage'),
        const SizedBox(height: 10),
        _ChipRow(
          options: const ['bootstrapped','friends_family','angel','seed','series_a+'],
          displayOptions: const ['Bootstrapped','Friends & Family','Angel','Seed','Series A+'],
          selected: fundingStage, color: color, onSelected: onFundingChanged,
        ),
        const SizedBox(height: 20),
        _InfoBanner(icon: Icons.lock_outline_rounded, text: 'This information is private and only used to personalize your AI advisor experience.', color: color),
      ]),
    );
  }
}

// PAGE 4 — Goals & Challenges
class _Page4Goals extends StatelessWidget {
  final TextEditingController goalCtrl;
  final List<String> allChallenges;
  final Set<String> selectedChallenges;
  final ValueChanged<String> onChallengeToggled;

  const _Page4Goals({
    required this.goalCtrl, required this.allChallenges,
    required this.selectedChallenges, required this.onChallengeToggled,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1976D2);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('Primary Goal with EMPORA'),
        const SizedBox(height: 8),
        _InputField(controller: goalCtrl, hint: 'e.g. Raise funds, manage compliance, grow revenue...', icon: Icons.flag_outlined, color: color, maxLines: 3),
        const SizedBox(height: 24),
        Row(children: [
          Text('Top Challenges', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Pick up to 3', style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: allChallenges.map((c) {
            final selected = selectedChallenges.contains(c);
            final disabled = !selected && selectedChallenges.length >= 3;
            return GestureDetector(
              onTap: disabled ? null : () => onChallengeToggled(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color : disabled ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: selected ? color : disabled ? Colors.grey.shade200 : const Color(0xFFE0E4F0), width: 1.5),
                  boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (selected) ...[const Icon(Icons.check_rounded, color: Colors.white, size: 14), const SizedBox(width: 5)],
                  Text(c, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : disabled ? Colors.grey.shade400 : const Color(0xFF1A1A2E))),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _InfoBanner(icon: Icons.auto_awesome_rounded, text: 'All 10 AI advisors will use this profile to give you personalized, context-aware advice every time.', color: color),
      ]),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color color;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({required this.controller, required this.hint, required this.icon, required this.color, this.keyboardType, this.maxLines = 1, this.inputFormatters});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, keyboardType: keyboardType, maxLines: maxLines, inputFormatters: inputFormatters,
    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A2E)),
    decoration: InputDecoration(
      hintText: hint, hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: color, size: 20),
      filled: true, fillColor: const Color(0xFFF5F7FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8EAF0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final List<String>? displayItems;
  final IconData icon;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _DropdownField({required this.hint, required this.value, required this.items, required this.icon, required this.color, required this.onChanged, this.displayItems});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    hint: Text(hint, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400)),
    onChanged: onChanged,
    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A2E)),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: color, size: 20),
      filled: true, fillColor: const Color(0xFFF5F7FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8EAF0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    items: items.asMap().entries.map((e) {
      final display = displayItems != null ? displayItems![e.key] : e.value;
      return DropdownMenuItem(value: e.value, child: Text(display));
    }).toList(),
  );
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> displayOptions;
  final String? selected;
  final Color color;
  final ValueChanged<String?> onSelected;

  const _ChipRow({required this.options, required this.displayOptions, required this.selected, required this.color, required this.onSelected});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: options.asMap().entries.map((e) {
      final isSelected = selected == e.value;
      return GestureDetector(
        onTap: () => onSelected(isSelected ? null : e.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isSelected ? color : const Color(0xFFE0E4F0), width: 1.5),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isSelected) ...[const Icon(Icons.check_rounded, color: Colors.white, size: 14), const SizedBox(width: 5)],
            Text(displayOptions[e.key], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1A1A2E))),
          ]),
        ),
      );
    }).toList(),
  );
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700, height: 1.5))),
    ]),
  );
}