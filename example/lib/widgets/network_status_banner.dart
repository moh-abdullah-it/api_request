import 'package:flutter/material.dart';
import '../config/app_config.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.useMockData) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(
            Icons.offline_bolt,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo Mode: Using mock data (network requests disabled)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Demo Mode'),
                  content: const Text(
                    'This app is running in demo mode with mock data to showcase functionality without requiring network access.\n\n'
                    'To enable live API calls, set AppConfig.useMockData to false in lib/config/app_config.dart',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Learn More',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
