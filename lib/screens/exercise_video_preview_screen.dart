import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/exercise.dart';
import 'dart:async';

class ExerciseVideoPreviewScreen extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onStartExercise;

  const ExerciseVideoPreviewScreen({
    super.key,
    required this.exercise,
    required this.onStartExercise,
  });

  @override
  State<ExerciseVideoPreviewScreen> createState() =>
      _ExerciseVideoPreviewScreenState();
}

class _ExerciseVideoPreviewScreenState
    extends State<ExerciseVideoPreviewScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _canStartExercise = false;
  bool _hasVideoCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hasVideoCompleted = false;
      });

      print('----------------------------------');
      print('LOADING VIDEO');
      print('Exercise: ${widget.exercise.name}');
      print('Video URL: ${widget.exercise.videoUrl}');
      print('----------------------------------');

      _videoPlayerController =
          VideoPlayerController.asset(widget.exercise.videoUrl);

      await _videoPlayerController
          .initialize()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(
            'Video initialization timed out after 10 seconds');
      });

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        allowPlaybackSpeedChanging: false,
        placeholder: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      );

      // Add listener for video completion
      _videoPlayerController.addListener(_onVideoProgress);

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });

      print('Video loaded successfully!');
    } catch (e, stackTrace) {
      print('----------------------------------');
      print('VIDEO INITIALIZATION ERROR');
      print('Exercise: ${widget.exercise.name}');
      print('Video URL: ${widget.exercise.videoUrl}');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('----------------------------------');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load video: $e';
        _canStartExercise = true; // Allow user to continue even if video fails
      });

      // Show a snackbar so user knows they can continue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Video could not be loaded. You can still continue with the exercise.'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Start Exercise',
            onPressed: widget.onStartExercise,
          ),
        ),
      );
    }
  }

  void _onVideoProgress() {
    if (_videoPlayerController.value.position >=
        _videoPlayerController.value.duration) {
      setState(() {
        _hasVideoCompleted = true;
        _canStartExercise = true;
      });
    }
  }

  void _replayVideo() {
    _videoPlayerController.seekTo(Duration.zero);
    _videoPlayerController.play();
    setState(() {
      _hasVideoCompleted = false;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget _buildNoVideoUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getExerciseIcon(widget.exercise.name),
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.exercise.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onStartExercise,
            child: const Text('Start Exercise'),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('stretch')) return Icons.accessibility_new;
    if (name.contains('rotation')) return Icons.rotate_right;
    if (name.contains('pose')) return Icons.self_improvement;
    if (name.contains('circles')) return Icons.circle;
    if (name.contains('flexion') || name.contains('extension')) {
      return Icons.straighten;
    }
    if (name.contains('twist')) return Icons.sync;
    if (name.contains('raise')) return Icons.arrow_upward;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_canStartExercise) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please watch the video before starting the exercise'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Exercise: ${widget.exercise.name}'),
          automaticallyImplyLeading: _canStartExercise,
          actions: [
            if (_canStartExercise)
              TextButton(
                onPressed: widget.onStartExercise,
                child: Text(
                  'Start Exercise',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Expanded(child: _buildNoVideoUI())
              else
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Chewie(controller: _chewieController!),
                      if (_hasVideoCompleted)
                        Positioned(
                          bottom: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _replayVideo,
                                icon: const Icon(Icons.replay),
                                label: const Text('Watch Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: widget.onStartExercise,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Exercise'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.exercise.instructions),
                    const SizedBox(height: 16),
                    Text(
                      'Benefits:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.exercise.benefits),
                    const SizedBox(height: 16),
                    Text(
                      'Precautions:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.exercise.precautions,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
