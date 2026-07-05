import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../data/alumni_repository.dart';

class EventGlassCard extends StatelessWidget {
  final AlumniEvent event;

  const EventGlassCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: AppTheme.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.mintGlow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RSVP',
                  style: TextStyle(color: AppTheme.mintGlow, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppTheme.mintGlow, size: 16),
              const SizedBox(width: 8),
              Text(event.date, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.mintGlow, size: 16),
              const SizedBox(width: 8),
              Text(event.location, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}