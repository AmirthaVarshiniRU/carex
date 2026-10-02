import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_progress.dart';
import '../providers/auth_provider.dart';
import '../services/progress_service.dart';
import '../services/patient_progress_service.dart';
import '../models/patient_progress.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProgressService _progressService = ProgressService();
  final PatientProgressService _patientProgressService = PatientProgressService();

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
    final userId = Provider.of<AuthProvider>(context).user?.uid;
    if (userId == null) return const Center(child: Text('Please log in to view progress'));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Rehab & Posture Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Week'), Tab(text: 'Month')],
        ),
      ),
      body: Column(
        children: [
          FutureBuilder<PatientProgressSummary>(
            future: _patientProgressService.getSummary(userId),
            builder: (context, snapshot) {
              final summary = snapshot.data ?? PatientProgressSummary.empty;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Stack(alignment: Alignment.center, children: [
                          SizedBox(height: 60, width: 60, child: CircularProgressIndicator(value: summary.overallProgress / 100, strokeWidth: 7, backgroundColor: Colors.white10, color: Colors.tealAccent)),
                          Text('${summary.overallProgress.round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ]),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Overall Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${summary.completedAssignedExercises}/${summary.totalAssignedExercises} assigned exercises completed • ${summary.totalSessions} recorded sessions', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _summaryMetric('Compliance', summary.totalAssignedExercises > 0 ? '${summary.compliancePercentage.round()}%' : 'Self-guided')),
                        Expanded(child: _summaryMetric('Form score', summary.averageFormScore > 0 ? '${summary.averageFormScore.round()}%' : '—')),
                        Expanded(child: _summaryMetric('Streak', '${summary.currentStreak} day${summary.currentStreak == 1 ? '' : 's'}')),
                      ]),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProgressView(_progressService.getTodayProgress(userId)),
                _buildProgressView(_progressService.getWeeklyProgress(userId)),
                _buildProgressView(_progressService.getMonthlyProgress(userId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))]);

  Widget _buildProgressView(Stream<List<ExerciseProgress>> stream) {
    return StreamBuilder<List<ExerciseProgress>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        final progresses = snapshot.data ?? [];
        if (progresses.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.fitness_center_rounded, size: 54, color: Colors.white24), SizedBox(height: 12), Text('No exercise logs yet', style: TextStyle(fontSize: 16, color: Colors.grey))]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: progresses.length,
          itemBuilder: (context, index) => _buildProgressCard(progresses[index]),
        );
      },
    );
  }

  Widget _buildProgressCard(ExerciseProgress progress) {
    final percent = progress.completionPercentage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(progress.exerciseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))), if (progress.formScore > 0) Text('${progress.formScore}% form', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: percent / 100, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${percent.toStringAsFixed(0)}% • ${progress.completedReps}/${progress.targetReps} reps', style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(_formatDate(progress.date), style: const TextStyle(color: Colors.grey, fontSize: 12))]),
      ]),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
