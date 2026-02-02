import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/box_manager.dart';
import '../../models/subscription/user_subscription_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  UserSubscription? _currentSubscription;
  bool _initialized = false;

  UserSubscription get currentSubscription => _currentSubscription ?? UserSubscription(userId: 'guest');
  
  bool get isPro => currentSubscription.isPlusOrHigher;    // Tier 1+
  bool get isElite => currentSubscription.isElite;         // Tier 2
  
  // Feature Checks
  bool get canAccessInvestments => isPro; 
  bool get canAccessAIInsights => isPro;
  bool get canAccessAtlasChat => isElite;

  Future<void> initialize() async {
    if (_initialized) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // Wait for login

    // Ensure box is open (BoxManager should handle this, but double check)
    // Note: BoxManager.openAllBoxes includes this if we update it.
    // For now, we assume BoxManager opens it or we open specifically.
    // Let's rely on BoxManager after we update it.
    
    _loadSubscription(userId);
    _initialized = true;
  }
  
  // Called after BoxManager opens boxes
  void _loadSubscription(String userId) {
    try {
      final box = BoxManager().getBox<UserSubscription>(BoxManager.subscriptionBoxName, userId);
      
      // Get first value or create default
      if (box.isNotEmpty) {
        _currentSubscription = box.values.first;
      } else {
        // Create default FREE subscription
        final sub = UserSubscription(userId: userId, tierIndex: 0);
        box.add(sub);
        _currentSubscription = sub;
      }
      notifyListeners();
    } catch (e) {
      print("Error loading subscription: $e");
    }
  }

  Future<void> upgradeTo(SubscriptionTier tier) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final box = BoxManager().getBox<UserSubscription>(BoxManager.subscriptionBoxName, userId);
    
    // Clear old (single subscription model)
    await box.clear();
    
    final newSub = UserSubscription(
      userId: userId,
      tierIndex: tier.index,
      expiryDate: null, // Lifetime for MVP demo, or set 30 days
      isActive: true,
    );
    
    await box.add(newSub);
    _currentSubscription = newSub;
    notifyListeners();
  }
  
  // Debug helper
  Future<void> resetToFree() async {
    await upgradeTo(SubscriptionTier.core);
  }
}
