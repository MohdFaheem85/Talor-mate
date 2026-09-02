import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// Centralized service tracking network status and Firestore sync state.
/// This service provides visual indicators (e.g. OfflineBanner) but NEVER blocks Firestore operations.
class SyncStatusService extends GetxService {
  final RxBool isOffline = false.obs;
  final RxBool isSyncing = false.obs;

  StreamSubscription? _syncSubscription;
  Timer? _connectivityTimer;
  bool _previousOfflineState = false;

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    // Periodic non-blocking connectivity check (every 4 seconds)
    _connectivityTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkConnectivity());

    // Listen to native Firestore sync events
    _syncSubscription = FirebaseFirestore.instance.snapshotsInSync().listen((_) {
      if (isOffline.value) {
        // If we received a sync event, Firestore has active network connection
        isOffline.value = false;
        _handleBackOnline();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      final connected = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;

      if (!connected) {
        isOffline.value = true;
        _previousOfflineState = true;
      } else {
        if (_previousOfflineState) {
          _handleBackOnline();
        }
        isOffline.value = false;
        _previousOfflineState = false;
      }
    } catch (_) {
      isOffline.value = true;
      _previousOfflineState = true;
    }
  }

  void _handleBackOnline() {
    isSyncing.value = true;
    Future.delayed(const Duration(seconds: 3), () {
      isSyncing.value = false;
    });
  }

  @override
  void onClose() {
    _syncSubscription?.cancel();
    _connectivityTimer?.cancel();
    super.onClose();
  }
}
