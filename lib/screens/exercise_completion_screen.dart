import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../providers/auth_provider.dart';
import '../models/exercise.dart';
import 'home_screen.dart';

class ExerciseCompletionScreen extends StatefulWidget {
  final String category;
  final int completedExercises;
  final int totalCaloriesBurned;
  final int totalMinutes;
  final Exercise currentExercise;

  // Pose-analysis results
  final int? completedReps;
  final int? targetReps;
  final int? qualityScore;

  const ExerciseCompletionScreen({
    super.key,
    required this.category,
    required this.completedExercises,
    required this.totalCaloriesBurned,
    required this.totalMinutes,
    required this.currentExercise,
    this.completedReps,
    this.targetReps,
    this.qualityScore,
  });

  @override
  State<ExerciseCompletionScreen> createState() =>
      _ExerciseCompletionScreenState();
}

class _ExerciseCompletionScreenState
    extends State<ExerciseCompletionScreen> {
  late ConfettiController _confettiController;

  bool _isAnimationComplete = false;
  bool _showVideo = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _confettiController.play();

    _updateUserProgress();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _isAnimationComplete = true;
      });
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;

      setState(() {
        _showVideo = true;
      });

      _initializeVideo();
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController =
          VideoPlayerController.asset(
        widget.currentExercise.videoUrl,
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load exercise video.';
      });

      debugPrint(
        'Error loading completion video: $e',
      );
    }
  }

  void _updateUserProgress() {
    // Keep the provider available for the existing
    // authentication/progress flow.
    Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    debugPrint(
      'Exercise completed: ${widget.currentExercise.name}',
    );

    debugPrint(
      'Category: ${widget.category}',
    );

    debugPrint(
      'Completed exercises: '
      '${widget.completedExercises}',
    );

    debugPrint(
      'Completed reps: '
      '${widget.completedReps ?? 0}',
    );

    debugPrint(
      'Target reps: '
      '${widget.targetReps ?? 0}',
    );

    debugPrint(
      'Quality score: '
      '${widget.qualityScore ?? 0}',
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF059669).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        _buildTrophy(),

                        const SizedBox(height: 24),

                        Text(
                          'Congratulations!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'You\'ve completed your '
                          '${widget.category} exercise session.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 40),

                        if (_isAnimationComplete)
                          _buildStats(),

                        if (_showVideo) ...[
                          const SizedBox(height: 40),
                          _buildVideoSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController:
                  _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _goHome,
          ),
          TextButton(
            onPressed: _goHome,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophy() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF059669)
            .withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.emoji_events,
        color: Color(0xFF059669),
        size: 80,
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        _buildStatCard(
          icon: Icons.fitness_center,
          title: 'Exercises Completed',
          value:
              widget.completedExercises.toString(),
        ),

        const SizedBox(height: 16),

        if (widget.completedReps != null) ...[
          _buildStatCard(
            icon: Icons.repeat,
            title: 'Repetitions Completed',
            value: widget.targetReps != null
                ? '${widget.completedReps} / '
                  '${widget.targetReps}'
                : '${widget.completedReps}',
          ),

          const SizedBox(height: 16),
        ],

        if (widget.qualityScore != null) ...[
          _buildStatCard(
            icon: Icons.stars,
            title: 'Exercise Quality',
            value:
                '${widget.qualityScore!.clamp(0, 100).toStringAsFixed(0)}%',
          ),

          const SizedBox(height: 16),
        ],

        _buildStatCard(
          icon: Icons.local_fire_department,
          title: 'Calories Burned',
          value:
              '${widget.totalCaloriesBurned} kcal',
        ),

        const SizedBox(height: 16),

        _buildStatCard(
          icon: Icons.timer,
          title: 'Total Time',
          value:
              '${widget.totalMinutes} min',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF059669),
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Watch Exercise Again',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading video...'),
              ],
            ),
          )
        else if (_errorMessage != null)
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),

                const SizedBox(height: 16),

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _initializeVideo,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_chewieController != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Chewie(
              controller: _chewieController!,
            ),
          ),

        const SizedBox(height: 24),

        _buildExerciseInformation(
          title: 'Instructions',
          content:
              widget.currentExercise.instructions,
        ),

        const SizedBox(height: 16),

        _buildExerciseInformation(
          title: 'Benefits',
          content:
              widget.currentExercise.benefits,
        ),

        const SizedBox(height: 16),

        _buildExerciseInformation(
          title: 'Precautions',
          content:
              widget.currentExercise.precautions,
        ),
      ],
    );
  }

  Widget _buildExerciseInformation({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: Theme.of(context)
              .textTheme
              .titleMedium,
        ),

        const SizedBox(height: 8),

        Text(
          content,
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}