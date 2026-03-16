// lib/models/module_model.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppModule {
  final int id;
  final String title;
  final String subtitle;
  final Color color;
  final Color lightColor;
  final IconData icon;

  const AppModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.lightColor,
    required this.icon,
  });
}

class ModuleData {
  static const List<AppModule> modules = [
    AppModule(
      id: 1,
      title: 'Fund Raising',
      subtitle: 'Manage investors & funding rounds',
      color: Color(0xFF1A3A6B),
      lightColor: Color(0xFFE8EEF9),
      icon: FontAwesomeIcons.handHoldingDollar,
    ),
    AppModule(
      id: 2,
      title: 'Strategy',
      subtitle: 'Business strategy & planning tools',
      color: Color(0xFF2756A8),
      lightColor: Color(0xFFEAF0FB),
      icon: FontAwesomeIcons.chess,
    ),
    AppModule(
      id: 3,
      title: 'Taxation',
      subtitle: 'Tax planning & compliance advisor',
      color: Color(0xFF27AE60),
      lightColor: Color(0xFFE8F8EF),
      icon: FontAwesomeIcons.fileInvoiceDollar,
    ),
    AppModule(
      id: 4,
      title: 'Land & Legal',
      subtitle: 'Property law & legal advisory',
      color: Color(0xFF8E44AD),
      lightColor: Color(0xFFF5EEF8),
      icon: FontAwesomeIcons.scaleBalanced,
    ),
    AppModule(
      id: 5,
      title: 'Licence',
      subtitle: 'Business licensing & permits',
      color: Color(0xFFE67E22),
      lightColor: Color(0xFFFDF0E0),
      icon: FontAwesomeIcons.idCard,
    ),
    AppModule(
      id: 6,
      title: 'Loans',
      subtitle: 'Loan options & financial planning',
      color: Color(0xFF00A8E8),
      lightColor: Color(0xFFE0F5FD),
      icon: FontAwesomeIcons.buildingColumns,
    ),
    AppModule(
      id: 7,
      title: 'Risk Management',
      subtitle: 'Identify & mitigate business risks',
      color: Color(0xFFE74C3C),
      lightColor: Color(0xFFFDECEB),
      icon: FontAwesomeIcons.shieldHalved,
    ),
    AppModule(
      id: 8,
      title: 'Project Management',
      subtitle: 'Plan, track & deliver projects',
      color: Color(0xFF16A085),
      lightColor: Color(0xFFE8F8F5),
      icon: FontAwesomeIcons.diagramProject,
    ),
    AppModule(
      id: 9,
      title: 'Cybersecurity',
      subtitle: 'Protect your digital assets',
      color: Color(0xFF2C3E50),
      lightColor: Color(0xFFEAEDF0),
      icon: FontAwesomeIcons.userShield,
    ),
    AppModule(
      id: 10,
      title: 'Restructure',
      subtitle: 'Business restructuring advisory',
      color: Color(0xFFF5A623),
      lightColor: Color(0xFFFEF5E4),
      icon: FontAwesomeIcons.arrowsRotate,
    ),
  ];
}