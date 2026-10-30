import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';

class DepthMeterWidget extends StatelessWidget {
  final ReflectionDepth depth;
  final String rationale;

  const DepthMeterWidget({
    Key? key,
    required this.depth,
    required this.rationale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color activeColor;
    String title;
    String badgeText;
    double progress;

    switch (depth) {
      case ReflectionDepth.superficial:
        activeColor = AppTheme.depthSuperficial;
        title = 'Superficial (Deskriptif Faktual)';
        badgeText = 'Level 1: Perlu Pendalaman';
        progress = 0.33;
        break;
      case ReflectionDepth.analytical:
        activeColor = AppTheme.depthAnalytical;
        title = 'Analytical (Reflektif Kritis)';
        badgeText = 'Level 2: Standar Portofolio';
        progress = 0.67;
        break;
      case ReflectionDepth.transformative:
        activeColor = AppTheme.depthTransformative;
        title = 'Transformative (Pergeseran Paradigma)';
        badgeText = 'Level 3: Sangat Mendalam';
        progress = 1.0;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activeColor.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: activeColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kedalaman Refleksi (AMEE 44)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rationale,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey[800],
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
