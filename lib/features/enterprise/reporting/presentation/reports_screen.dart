import 'package:flutter/material.dart';
import 'package:gemini_live_ghost_accountant/core/theme/app_colors.dart';
import 'package:gemini_live_ghost_accountant/core/theme/glass_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Advanced Reports', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics, size: 64, color: AppColors.success),
                        const SizedBox(height: 16),
                        const Text('Advanced Reporting', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Custom reports & dashboards', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('Coming in Phase 5.3', style: TextStyle(color: AppColors.success, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
