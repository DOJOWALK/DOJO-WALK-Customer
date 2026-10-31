import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DojoWalkTheme.background,
      appBar: AppBar(
        backgroundColor: DojoWalkTheme.background,
        foregroundColor: DojoWalkTheme.text,
        elevation: 0,
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: DojoWalkTheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 48,
                  color: DojoWalkTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noNotificationsYet,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: DojoWalkTheme.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.notificationsNotConnected,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: DojoWalkTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
