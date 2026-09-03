import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/sync_status_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncStatusService>()) {
      return const SizedBox.shrink();
    }

    final syncService = Get.find<SyncStatusService>();

    return Obx(() {
      final isOffline = syncService.isOffline.value;
      final isSyncing = syncService.isSyncing.value;

      if (!isOffline && !isSyncing) {
        return const SizedBox.shrink();
      }

      if (isOffline) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Amber 100
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFCD34D)), // Amber 300
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFF92400E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline Mode — All changes are saved locally & will sync when online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E), // Amber 800
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // isSyncing == true
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE), // Blue 100
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF93C5FD)), // Blue 300
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Syncing changes to cloud...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF), // Blue 800
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
