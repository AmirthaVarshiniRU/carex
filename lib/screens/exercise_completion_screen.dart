import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math';
import '../providers/auth_provider.dart';
import '../models/exercise.dart';
import 'home_screen.dart';

class ExerciseCompletionScreen extends StatefulWidget {
  final String category;
  final int completedExercises;
  final int totalCaloriesBurned;
  final int totalMinutes;
  final Exercise currentExercise;

  const ExerciseCompletionScreen({
    Key? key,
    required this.category,
    required this.completedExercises,
    required this.totalCaloriesBurned,
    required this.totalMinutes,
    required this.currentExercise,
  }) : super(key: key);

  @override
  _ExerciseCompletionScreenState createState() =>
      _ExerciseCompletionScreenState();
}

class _ExerciseCompletionScreenState extends State<ExerciseCompletionScreen> {
  late ConfettiController _confettiController;
  bool _isAnimationComplete = false;
  bool _showVideo = false;
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _updateUserProgress();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnimationComplete = true;
        });
      }
    });

    // Initialize video after showing stats
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showVideo = true;
        });
        _initializeVideo();
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController =
          VideoPlayerController.asset(widget.currentExercise.videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
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

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load video. Please try again later.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _updateUserProgress() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // In a real app, this would update the user's progress in the database
    // For now, we'll just print the progress to the console
    debugPrint('Updated user progress for ${widget.category}');
    debugPrint('Completed exercises: ${widget.completedExercises}');
    debugPrint('Total calories burned: ${widget.totalCaloriesBurned}');
    debugPrint('Total minutes: ${widget.totalMinutes}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
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

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        },
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
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Trophy icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Color(0xFF059669),
                              size: 80,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Congratulations text
                          Text(
                            'Congratulations!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Description
                          Text(
                            'You\'ve completed all exercises for ${widget.category}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Stats
                          if (_isAnimationComplete) ...[
                            _buildStatCard(
                              icon: Icons.fitness_center,
                              title: 'Exercises Completed',
                              value: widget.completedExercises.toString(),
                            ),
                            const SizedBox(height: 16),
                            _buildStatCard(
                              icon: Icons.local_fire_department,
                              title: 'Calories Burned',
                              value: '${widget.totalCaloriesBurned} kcal',
                            ),
                            const SizedBox(height: 16),
                            _buildStatCard(
                              icon: Icons.timer,
                              title: 'Total Time',
                              value: '${widget.totalMinutes} min',
                            ),
                          ],

                          // Video section
                          if (_showVideo) ...[
                            const SizedBox(height: 40),
                            Text(
                              'Watch Exercise Again',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            if (_isLoading)
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
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
                                child: Chewie(controller: _chewieController!),
                              )
                            else
                              const Center(
                                child: Text('Video player not available'),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Instructions:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(widget.currentExercise.instructions),
                            const SizedBox(height: 16),
                            Text(
                              'Benefits:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(widget.currentExercise.benefits),
                            const SizedBox(height: 16),
                            Text(
                              'Precautions:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(widget.currentExercise.precautions),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // straight up
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
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
              color: const Color(0xFF059669).withOpacity(0.1),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
}
