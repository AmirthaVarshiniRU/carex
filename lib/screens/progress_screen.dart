import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_progress.dart';
import '../providers/auth_provider.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProgressService _progressService = ProgressService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;
    if (userId == null) {
      return const Center(child: Text('Please log in to view progress'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Rehab & Posture Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Posture & Weekly Analytics Overview Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Posture Accuracy Score Circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            height: 60,
                            width: 60,
                            child: CircularProgressIndicator(
                              value: 0.94,
                              strokeWidth: 7,
                              backgroundColor: Colors.white10,
                              color: Colors.tealAccent,
                            ),
                          ),
                          const Text(
                            '94%',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'AI Form Quality: 94%',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Spine & shoulder alignment remained optimal across 12 exercise sessions.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),

                  // Mini Weekly Minutes Bar Graph
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Weekly Minutes', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('38 Mins Total', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('M', 0.4),
                      _buildBar('T', 0.7),
                      _buildBar('W', 0.9),
                      _buildBar('T', 0.5),
                      _buildBar('F', 0.8),
                      _buildBar('S', 0.6),
                      _buildBar('S', 0.3),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Exercises List Views in TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProgressView(
                  stream: _progressService.getTodayProgress(userId),
                  title: 'Today\'s Progress',
                ),
                _buildProgressView(
                  stream: _progressService.getWeeklyProgress(userId),
                  title: 'Weekly Progress',
                ),
                _buildProgressView(
                  stream: _progressService.getMonthlyProgress(userId),
                  title: 'Monthly Progress',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor) {
    return Column(
      children: [
        Container(
          height: 35 * heightFactor,
          width: 14,
          decoration: BoxDecoration(
            color: Colors.tealAccent.withOpacity(heightFactor > 0.7 ? 1.0 : 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildProgressView({
    required Stream<List<ExerciseProgress>> stream,
    required String title,
  }) {
    return StreamBuilder<List<ExerciseProgress>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        final progresses = snapshot.data ?? [];
        if (progresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.fitness_center_rounded, size: 54, color: Colors.white24),
                SizedBox(height: 12),
                Text('No exercise logs yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: progresses.length,
          itemBuilder: (context, index) {
            final progress = progresses[index];
            return _buildProgressCard(progress);
          },
        );
      },
    );
  }

  Widget _buildProgressCard(ExerciseProgress progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  progress.exerciseName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMoodColor(progress.mood).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  progress.mood,
                  style: TextStyle(color: _getMoodColor(progress.mood), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.completionPercentage / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress.completionPercentage)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.completionPercentage.toStringAsFixed(0)}% Complete',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                _formatDate(progress.date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.greenAccent;
      case 'energetic':
        return Colors.orangeAccent;
      case 'tired':
        return Colors.blueAccent;
      case 'stressed':
        return Colors.redAccent;
      default:
        return Colors.tealAccent;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 90) return Colors.greenAccent;
    if (percentage >= 70) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

