import 'package:flutter/material.dart';
import 'app_config.dart';
import 'app_theme.dart';

/// Environment banner widget to show current environment
/// Only visible in non-production environments
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show banner in production
    if (!AppConfig.isDebug) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Color(AppConfig.environmentColor).withOpacity(0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.developer_mode,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AppConfig.environmentName.toUpperCase()} MODE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'v${AppConfig.appVersion}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings indicator to show API URL and environment
class EnvironmentSettingsIndicator extends StatelessWidget {
  const EnvironmentSettingsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDebug) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(AppConfig.environmentColor).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Color(AppConfig.environmentColor),
              ),
              const SizedBox(width: 4),
              Text(
                'Environment Info',
                style: TextStyle(
                  color: Color(AppConfig.environmentColor),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _InfoRow(
            label: 'Mode',
            value: AppConfig.environmentName,
          ),
          _InfoRow(
            label: 'API',
            value: AppConfig.apiBaseUrl,
          ),
          _InfoRow(
            label: 'Version',
            value: AppConfig.appVersion,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.outline,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
