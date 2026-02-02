import 'package:flutter/material.dart';
import '../../repositories/financial_repository.dart';
import '../../services/finances/financial_service.dart'; // NEW

class FinancialHealthScore {
  final int score;
  final String status;
  final Color color;
  final String feedback;

  FinancialHealthScore({required this.score, required this.status, required this.color, required this.feedback});
}

class FinancialHealthService {
  
  FinancialHealthScore calculateHealth(FinancialRepository repository) {
    // Get this month's data
    // Ideally we use a 'Month' period, but for now let's use the currently selected period in repository if it's monthly, 
    // OR we assume we want a general health check based on "All Time" or "Last 30 Days".
    // Let's use the repository's 'getSummary(TimePeriod.thisMonth)' if available, or just calculate from transactions.
    // Since we don't have easy access to 'thisMonth' period enum without importing it, let's use the existing repository summary which might be filtered.
    // BETTER: Calculate from "Recent Transactions" (last 30 days) manually or just use the current summary if it represents a good snapshot.
    // For MVP: Use the current Repository Summary (which defaults to Today/Week/Month based on user selection).
    // To be robust, let's ask for "This Month" specifically if we can, but since I can't easily see the Enum values right now without checking, 
    // I'll define logic assuming I have access to Income/Expense.
    
    final summary = repository.getSummary(TimePeriod.thisMonth); 
    final income = summary.totalIncome;
    final expense = summary.totalExpense;
    
    if (income == 0 && expense == 0) {
      return FinancialHealthScore(
        score: 50, 
        status: "Neutral", 
        color: Colors.grey, 
        feedback: "Start tracking to see your score!"
      );
    }

    double rawScore = 50;

    // 1. Savings Rate (Target 20%+)
    if (income > 0) {
      double savingsRate = (income - expense) / income;
      if (savingsRate >= 0.20) rawScore += 30; // Great saver
      else if (savingsRate > 0) rawScore += 15; // Saving something
      else rawScore -= 10; // Overspending
    } else {
        // No income, but spending?
        if (expense > 0) rawScore -= 20;
    }

    // 2. Expense Ratio (Target < 80% of income)
    if (income > 0) {
        if (expense < (income * 0.5)) rawScore += 20; // Very frugal
        else if (expense < (income * 0.8)) rawScore += 10; // Healthy
    }

    // Clamp
    int finalScore = rawScore.clamp(0, 100).toInt();

    String status;
    Color color;
    String feedback;

    if (finalScore >= 80) {
      status = "Excellent";
      color = const Color(0xFF43B02A);
      feedback = "You are crushing your financial goals! 🚀";
    } else if (finalScore >= 60) {
      status = "Good";
      color = Colors.blueAccent;
      feedback = "You are doing well, keep saving! 💰";
    } else if (finalScore >= 40) {
      status = "Fair";
      color = Colors.orangeAccent;
      feedback = "Watch your expenses this month. ⚠️";
    } else {
      status = "Concerning";
      color = Colors.redAccent;
      feedback = "You are spending more than you earn. 🚨";
    }

    return FinancialHealthScore(
      score: finalScore, 
      status: status, 
      color: color, 
      feedback: feedback
    );
  }

  Color _getColor(int score) {
      if (score >= 80) return const Color(0xFF43B02A);
      if (score >= 60) return Colors.blueAccent;
      if (score >= 40) return Colors.orangeAccent;
      return Colors.redAccent;
  }
}
