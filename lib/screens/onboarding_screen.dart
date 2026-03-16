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

  // ── Form data ──────────────────────────────────────────────────────────────
  // Page 1 — Personal
  final _phoneCtrl   = TextEditingController();
  final _cityCtrl    = TextEditingController();
  String? _state;

  // Page 2 — Business
  final _bizNameCtrl = TextEditingController();
  String? _bizType;
  final _industryCtrl = TextEditingController();
  String? _bizStage;
  String? _teamSize;

  // Page 3 — Financials
  String? _annualRevenue;
  String? _fundingStage;
  final _yearCtrl = TextEditingController();

  // Page 4 — Goals
  final _goalCtrl = TextEditingController();
  final List<String> _allChallenges = [
    'Getting customers',
    'Raising funds',
    'Managing cash flow',
    'Tax & compliance',
    'Hiring & team',
    'Legal & contracts',
    'Technology',
    'Scaling operations',
    'Market competition',
    'Loan & debt management',
  ];
  final Set<String> _selectedChallenges = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bizNameCtrl.dispose();
    _industryCtrl.dispose();
    _goalCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ApiService.saveFounderProfile({
        'phone':         _phoneCtrl.text.trim(),
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _Header(
              currentPage: _currentPage,
              onSkip: _skip,
            ),

            // ── Progress bar ─────────────────────────────────────────────────
            _ProgressBar(currentPage: _currentPage, total: 4),

            // ── Pages ────────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Page1Personal(
                    phoneCtrl: _phoneCtrl,
                    cityCtrl: _cityCtrl,
                    state: _state,
                    onStateChanged: (v) => setState(() => _state = v),
                  ),
                  _Page2Business(
                    bizNameCtrl: _bizNameCtrl,
                    industryCtrl: _industryCtrl,
                    bizType: _bizType,
                    bizStage: _bizStage,
                    teamSize: _teamSize,
                    onBizTypeChanged:  (v) => setState(() => _bizType  = v),
                    onBizStageChanged: (v) => setState(() => _bizStage = v),
                    onTeamSizeChanged: (v) => setState(() => _teamSize = v),
                  ),
                  _Page3Financials(
                    yearCtrl: _yearCtrl,
                    annualRevenue: _annualRevenue,
                    fundingStage:  _fundingStage,
                    onRevenueChanged: (v) => setState(() => _annualRevenue = v),
                    onFundingChanged: (v) => setState(() => _fundingStage  = v),
                  ),
                  _Page4Goals(
                    goalCtrl: _goalCtrl,
                    allChallenges: _allChallenges,
                    selectedChallenges: _selectedChallenges,
                    onChallengeToggled: (c) => setState(() {
                      if (_selectedChallenges.contains(c)) {
                        _selectedChallenges.remove(c);
                      } else if (_selectedChallenges.length < 3) {
                        _selectedChallenges.add(c);
                      }
                    }),
                  ),
                ],
              ),
            ),

            // ── Bottom nav ───────────────────────────────────────────────────
            _BottomNav(
              currentPage: _currentPage,
              saving: _saving,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int currentPage;
  final VoidCallback onSkip;
  const _Header({required this.currentPage, required this.onSkip});

  static const _titles = [
    'Tell us about yourself',
    'Your business',
    'Financial snapshot',
    'Your goals',
  ];
  static const _subtitles = [
    'So we can personalize your experience',
    'Help us understand your venture',
    'We\'ll tailor advice to your stage',
    'What do you want to achieve?',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('E',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('EMPORA',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: Text('Skip for now',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _titles[currentPage],
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitles[currentPage],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int currentPage;
  final int total;
  const _ProgressBar({required this.currentPage, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= currentPage;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentPage;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _BottomNav({
    required this.currentPage,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: Text('Back',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          if (currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: saving ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      isLast ? 'Complete Setup 🚀' : 'Continue',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PAGE 1 — Personal Info
// ────────────────────────────────────────────────────────────────────────────
class _Page1Personal extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController cityCtrl;
  final String? state;
  final ValueChanged<String?> onStateChanged;

  const _Page1Personal({
    required this.phoneCtrl,
    required this.cityCtrl,
    required this.state,
    required this.onStateChanged,
  });

  static const _states = [
    'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh',
    'Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka',
    'Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram',
    'Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana',
    'Tripura','Uttar Pradesh','Uttarakhand','West Bengal',
    'Delhi','Chandigarh','Puducherry','Other',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          _Field(
            label: 'Phone Number',
            hint: '+91 98765 43210',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'City',
            hint: 'e.g. Chennai, Mumbai, Bangalore',
            controller: cityCtrl,
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 16),
          _Dropdown(
            label: 'State',
            hint: 'Select your state',
            value: state,
            items: _states,
            icon: Icons.map_outlined,
            onChanged: onStateChanged,
          ),
          const SizedBox(height: 20),
          _InfoCard(
            icon: Icons.privacy_tip_outlined,
            text: 'Your information is private and only used to personalize your AI advisor experience.',
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PAGE 2 — Business Info
// ────────────────────────────────────────────────────────────────────────────
class _Page2Business extends StatelessWidget {
  final TextEditingController bizNameCtrl;
  final TextEditingController industryCtrl;
  final String? bizType;
  final String? bizStage;
  final String? teamSize;
  final ValueChanged<String?> onBizTypeChanged;
  final ValueChanged<String?> onBizStageChanged;
  final ValueChanged<String?> onTeamSizeChanged;

  const _Page2Business({
    required this.bizNameCtrl,
    required this.industryCtrl,
    required this.bizType,
    required this.bizStage,
    required this.teamSize,
    required this.onBizTypeChanged,
    required this.onBizStageChanged,
    required this.onTeamSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          _Field(
            label: 'Business / Startup Name',
            hint: 'e.g. Acme Technologies',
            controller: bizNameCtrl,
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Industry / Sector',
            hint: 'e.g. Fintech, Agri, Retail, Healthcare',
            controller: industryCtrl,
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 16),
          _Dropdown(
            label: 'Business Structure',
            hint: 'Select structure',
            value: bizType,
            items: const ['sole_proprietor','partnership','llp','pvt_ltd','opc','other'],
            displayItems: const ['Sole Proprietor','Partnership','LLP','Pvt Ltd','OPC','Other'],
            icon: Icons.account_balance_outlined,
            onChanged: onBizTypeChanged,
          ),
          const SizedBox(height: 16),
          _ChipSelector(
            label: 'Business Stage',
            options: const ['idea','mvp','early_revenue','scaling','established'],
            displayOptions: const ['Idea Stage','MVP Ready','Early Revenue','Scaling','Established'],
            selected: bizStage,
            onSelected: onBizStageChanged,
          ),
          const SizedBox(height: 16),
          _ChipSelector(
            label: 'Team Size',
            options: const ['solo','2-5','6-10','11-50','50+'],
            displayOptions: const ['Solo','2–5','6–10','11–50','50+'],
            selected: teamSize,
            onSelected: onTeamSizeChanged,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PAGE 3 — Financials
// ────────────────────────────────────────────────────────────────────────────
class _Page3Financials extends StatelessWidget {
  final TextEditingController yearCtrl;
  final String? annualRevenue;
  final String? fundingStage;
  final ValueChanged<String?> onRevenueChanged;
  final ValueChanged<String?> onFundingChanged;

  const _Page3Financials({
    required this.yearCtrl,
    required this.annualRevenue,
    required this.fundingStage,
    required this.onRevenueChanged,
    required this.onFundingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          _Field(
            label: 'Year Founded',
            hint: 'e.g. 2021',
            controller: yearCtrl,
            keyboardType: TextInputType.number,
            icon: Icons.calendar_today_outlined,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          _ChipSelector(
            label: 'Annual Revenue',
            options: const ['pre_revenue','under_10l','10l_50l','50l_1cr','1cr_5cr','5cr+'],
            displayOptions: const ['Pre-revenue','Under ₹10L','₹10L–50L','₹50L–1Cr','₹1Cr–5Cr','₹5Cr+'],
            selected: annualRevenue,
            onSelected: onRevenueChanged,
          ),
          const SizedBox(height: 20),
          _ChipSelector(
            label: 'Funding Stage',
            options: const ['bootstrapped','friends_family','angel','seed','series_a+'],
            displayOptions: const ['Bootstrapped','Friends & Family','Angel Funded','Seed Stage','Series A+'],
            selected: fundingStage,
            onSelected: onFundingChanged,
          ),
          const SizedBox(height: 20),
          _InfoCard(
            icon: Icons.info_outline,
            text: 'This helps our AI give you accurate financial and investment advice.',
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PAGE 4 — Goals & Challenges
// ────────────────────────────────────────────────────────────────────────────
class _Page4Goals extends StatelessWidget {
  final TextEditingController goalCtrl;
  final List<String> allChallenges;
  final Set<String> selectedChallenges;
  final ValueChanged<String> onChallengeToggled;

  const _Page4Goals({
    required this.goalCtrl,
    required this.allChallenges,
    required this.selectedChallenges,
    required this.onChallengeToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: 'What is your primary goal with EMPORA?',
            hint: 'e.g. Raise funds, manage compliance, grow revenue...',
            controller: goalCtrl,
            icon: Icons.flag_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Top challenges (pick up to 3)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allChallenges.map((c) {
              final selected = selectedChallenges.contains(c);
              return GestureDetector(
                onTap: () => onChallengeToggled(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    c,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            icon: Icons.auto_awesome_outlined,
            text: 'All 10 AI advisors will use this profile to give you personalized, context-aware advice every time.',
            color: AppTheme.accent,
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData icon;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final List<String>? displayItems;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.displayItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.asMap().entries.map((e) {
            final display = displayItems != null ? displayItems![e.key] : e.value;
            return DropdownMenuItem(value: e.value, child: Text(display));
          }).toList(),
        ),
      ],
    );
  }
}

class _ChipSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> displayOptions;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _ChipSelector({
    required this.label,
    required this.options,
    required this.displayOptions,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.asMap().entries.map((e) {
            final isSelected = selected == e.value;
            return GestureDetector(
              onTap: () => onSelected(isSelected ? null : e.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.divider,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  displayOptions[e.key],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoCard({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}