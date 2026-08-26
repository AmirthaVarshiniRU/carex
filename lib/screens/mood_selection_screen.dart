import 'package:flutter/material.dart';
import 'exercise_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/ml_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MoodSelectionScreen extends StatefulWidget {
  final String category;

  const MoodSelectionScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  _MoodSelectionScreenState createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  late AnimationController _animationController;
  final MLService _mlService = MLService();
  bool _isLoading = false;

  // Updated questions and answers for assessment
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'How was your sleep last night?',
      'answers': [
        'Great (8+ hours, fully refreshed)',
        'Good (6-8 hours, well-rested)',
        'Okay (4-6 hours, somewhat tired)',
        'Poor (Less than 4 hours, exhausted)'
      ],
      'selectedAnswer': 'Good (6-8 hours, well-rested)',
    },
    {
      'question': 'Have you eaten in the last few hours?',
      'answers': [
        'Yes, a balanced meal, feeling good',
        'Yes, but it was a light snack',
        'No, but I don\'t feel too hungry',
        'No, and I feel weak or low on energy'
      ],
      'selectedAnswer': 'Yes, a balanced meal, feeling good',
    },
    {
      'question': 'When faced with a difficult task, what is your first thought?',
      'answers': [
        'Let\'s find a way to tackle this',
        'I\'ll plan first before jumping in',
        'This feels overwhelming; I need a break',
        'I don\'t think I can handle this right now'
      ],
      'selectedAnswer': 'Let\'s find a way to tackle this',
    },
    {
      'question': 'If you had to take the stairs instead of the elevator, how would you feel?',
      'answers': [
        'No problem I\'d take them without a second thought',
        'I\'d take them, but at a steady pace',
        'I\'d hesitate, but I could manage',
        'I\'d avoid it if possible I feel too drained'
      ],
      'selectedAnswer': 'I\'d take them, but at a steady pace',
    },
    {
      'question': 'If someone asked you to focus on a 10-minute guided meditation, what would your first thought be?',
      'answers': [
        'Sounds good I can focus easily',
        'I could try, but I might check the time',
        'I don\'t think I can sit still right now',
        'I\'d rather not I feel too restless or drained'
      ],
      'selectedAnswer': 'I could try, but I might check the time',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    _loadMLModel();
  }

  Future<void> _loadMLModel() async {
    try {
      await _mlService.loadModel();
    } catch (e) {
      print('Error loading ML model: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading mood prediction model. Using default prediction.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _goToExercisePage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert answers to numerical values (0-3)
      final answers = questions.map((q) {
        final selectedAnswer = q['selectedAnswer'] as String;
        return q['answers'].indexOf(selectedAnswer);
      }).toList().cast<int>();

      print('User answers converted to numbers: $answers');

      // Get mood & intensity prediction from XGBoost ML model
      final xgbResult = await _mlService.predictMoodWithXGBoost(answers);
      final predictedMood = xgbResult.predictedMood;
      final confidencePct = (xgbResult.confidenceScore * 100).toStringAsFixed(1);
      final intensity = xgbResult.recommendedIntensity;


      // Update user's mood in AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUserMood(predictedMood);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show rich XGBoost Model Analysis Modal Dialog
        _showXGBoostAnalysisModal(context, xgbResult, authProvider.user?.uid ?? '');
      }
    } catch (e) {
      print('Error in mood prediction: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error predicting mood. Using default mood.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Add a small delay to show the error message
        await Future.delayed(const Duration(seconds: 2));

        // Navigate with default mood
        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ExercisePage(
                userId: Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '',
                mood: 'Neutral',
                exerciseType: widget.category,
                healthCondition: 'general',
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectAnswer(String answer) {
    setState(() {
      questions[currentQuestionIndex]['selectedAnswer'] = answer;
    });
  }

  void _nextQuestion() {
    _animationController.reset();
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      }
    });
    _animationController.forward();
  }

  void _previousQuestion() {
    _animationController.reset();
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
      }
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF059669).withOpacity(0.8),
              const Color(0xFF1A3FA8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Question ${currentQuestionIndex + 1}/${questions.length}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subtitle or Question
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        questions[currentQuestionIndex]['question'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Content based on current step
                    Expanded(
                      child: FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeOut,
                          )),
                          child: _buildQuestionScreen(),
                        ),
                      ),
                    ),

                    // Progress indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: LinearProgressIndicator(
                        value: (currentQuestionIndex + 1) / questions.length,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                    ),

                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          if (currentQuestionIndex > 0)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _previousQuestion,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Previous',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: currentQuestionIndex == questions.length - 1
                                    ? _goToExercisePage
                                    : _nextQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF059669),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                ),
                                child: Text(
                                  currentQuestionIndex == questions.length - 1
                                      ? 'Proceed to Exercises'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen() {
    final questionData = questions[currentQuestionIndex];
    final answers = questionData['answers'] as List<String>;
    final selectedAnswer = questionData['selectedAnswer'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            questionData['question'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final answer = answers[index];
                final isSelected = selectedAnswer == answer;

                return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: GestureDetector(
                            onTap: () => _selectAnswer(answer),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFF059669).withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFF059669) : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF059669)
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      answer,
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            isSelected ? FontWeight.bold : FontWeight.normal,
                                        color:
                                            isSelected ? const Color(0xFF059669) : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

              },
            ),
          ),
        ),
      ],
    );
  }
}
