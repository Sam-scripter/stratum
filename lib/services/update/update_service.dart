import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../theme/app_theme.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check connectivity status
  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Check for updates and perform an immediate update if available.
  /// This blocks the UI until the update is installed.
  Future<void> checkImmediateUpdate() async {
    try {
      if (!await _isConnected()) return;

      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      print('Update check failed: $e');
    }
  }

  /// Check for updates and perform a flexible update (background download).
  /// Shows a SnackBar when ready to install.
  Future<void> checkFlexibleUpdate(BuildContext context) async {
    try {
      // Optimization: Don't check if offline
      if (!await _isConnected()) return;

      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Start background download
        await InAppUpdate.startFlexibleUpdate();
        
        // When download completes (await returns), prompt user to restart
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An update has just been downloaded!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 10), // Give them time
              action: SnackBarAction(
                label: 'RESTART',
                textColor: AppTheme.primaryDark,
                onPressed: () {
                  InAppUpdate.completeFlexibleUpdate();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Update check failed: $e');
    }
  }
}
