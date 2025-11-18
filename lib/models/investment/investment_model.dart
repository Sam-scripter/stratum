import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum InvestmentType {
  moneyMarket,
  sacco,
  bonds,
  stocks,
  realEstate,
  other,
}

class Investment {
  final String id;
  final String name;
  final InvestmentType type;
  final double investedAmount;
  final double currentValue;
  final double returnRate; // Percentage
  final DateTime dateInvested;
  final String? provider;
  final String? notes;
  final String? referenceNumber;

  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    required this.returnRate,
    required this.dateInvested,
    this.provider,
    this.notes,
    this.referenceNumber,
  });

  String get typeName {
    switch (type) {
      case InvestmentType.moneyMarket:
        return 'Money Market';
      case InvestmentType.sacco:
        return 'SACCO Shares';
      case InvestmentType.bonds:
        return 'Government Bonds';
      case InvestmentType.stocks:
        return 'Stocks';
      case InvestmentType.realEstate:
        return 'Real Estate';
      case InvestmentType.other:
        return 'Other';
    }
  }

  String get typeEmoji {
    switch (type) {
      case InvestmentType.moneyMarket:
        return '💰';
      case InvestmentType.sacco:
        return '🏦';
      case InvestmentType.bonds:
        return '📜';
      case InvestmentType.stocks:
        return '📈';
      case InvestmentType.realEstate:
        return '🏠';
      case InvestmentType.other:
        return '💼';
    }
  }

  double get gainLoss => currentValue - investedAmount;
  bool get isPositive => returnRate >= 0;

  String get formattedInvestedAmount => 'KES ${investedAmount.toStringAsFixed(2)}';
  String get formattedCurrentValue => 'KES ${currentValue.toStringAsFixed(2)}';
  String get formattedGainLoss {
    final amount = gainLoss.abs();
    return '${isPositive ? '+' : '-'}KES ${amount.toStringAsFixed(2)}';
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(dateInvested);
  String get formattedReturnRate => '${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(2)}%';
}

class InvestmentOpportunity {
  final String id;
  final String name;
  final String expectedReturn;
  final String minimumInvestment;
  final String riskLevel;
  final InvestmentType type;
  final String? description;
  final String? provider;

  InvestmentOpportunity({
    required this.id,
    required this.name,
    required this.expectedReturn,
    required this.minimumInvestment,
    required this.riskLevel,
    required this.type,
    this.description,
    this.provider,
  });

  String get typeName {
    switch (type) {
      case InvestmentType.moneyMarket:
        return 'Money Market';
      case InvestmentType.sacco:
        return 'SACCO Shares';
      case InvestmentType.bonds:
        return 'Government Bonds';
      case InvestmentType.stocks:
        return 'Stocks';
      case InvestmentType.realEstate:
        return 'Real Estate';
      case InvestmentType.other:
        return 'Other';
    }
  }

  String get typeEmoji {
    switch (type) {
      case InvestmentType.moneyMarket:
        return '💰';
      case InvestmentType.sacco:
        return '🏦';
      case InvestmentType.bonds:
        return '📜';
      case InvestmentType.stocks:
        return '📈';
      case InvestmentType.realEstate:
        return '🏠';
      case InvestmentType.other:
        return '💼';
    }
  }

  Color get riskColor {
    switch (riskLevel.toLowerCase()) {
      case 'low risk':
        return const Color(0xFF10B981); // Green
      case 'medium risk':
        return const Color(0xFFF59E0B); // Orange
      case 'high risk':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

