import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:submersion/features/auto_update/presentation/providers/update_providers.dart';

const _channel = MethodChannel('app.submersion/updates');

/// Registers a method channel handler that allows native menu items
/// to trigger an interactive update check.
void registerUpdateMenuChannel(WidgetRef ref) {
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'checkForUpdateInteractively') {
      await ref
          .read(updateStatusProvider.notifier)
          .checkForUpdateInteractively();
    }
  });
}
