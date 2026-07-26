import 'dart:io';
import 'package:flutter/material.dart';
import '../data/isar_service.dart';
import '../data/models/exercise_badge.dart';
import '../services/badge_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mapper.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<ExerciseBadge> _allBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    final badges = await IsarService.instance.getAllBadges();
    setState(() {
      _allBadges = badges;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _allBadges.where((b) => b.isUnlocked).length;
    final totalCount = _allBadges.length;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allBadges.isEmpty
          ? const Center(child: Text("Nu există insigne disponibile."))
          : Column(
        children: [
          // Header cu Progresul
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: AppColors.warning, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      '$unlockedCount din $totalCount Deblocate',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Grila de Badge-uri
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBadges,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _allBadges.length,
                itemBuilder: (context, index) {
                  final badge = _allBadges[index];
                  return _buildBadgeCard(badge);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(ExerciseBadge badge) {
    final isUnlocked = badge.isUnlocked;

    return InkWell(
      onTap: () => BadgeService.showBadgeDetailDialog(this.context, badge),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: isUnlocked ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnlocked ? AppColors.primary : Colors.grey.shade300,
            width: isUnlocked ? 1.5 : 0.5,
          ),
        ),
        color: isUnlocked ? AppColors.surface : Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isUnlocked ? AppColors.warning : Colors.grey.shade300,
                    child: Icon(
                      IconMapper.getIcon(badge.iconName),
                      size: 32,
                      color: isUnlocked ? Colors.amber.shade900 : Colors.grey.shade600,
                    ),
                  ),
                  if (!isUnlocked)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.lock, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isUnlocked ? Colors.black87 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isUnlocked ? AppColors.textPrimary : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} la ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}