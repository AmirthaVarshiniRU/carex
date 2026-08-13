import 'package:google_generative_ai/google_generative_ai.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIAssistantService {
  // Optional Gemini API Key (Can be set or passed dynamically)
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  GenerativeModel? _geminiModel;

  AIAssistantService() {
    if (_geminiApiKey.isNotEmpty) {
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
        systemInstruction: Content.system(
          'You are CareX AI, an expert physical therapy and ergonomic advisor. '
          'Provide concise, supportive, and practical posture, stretching, and rehab guidance.',
        ),
      );
    }
  }

  /// Generates a response using Gemini AI, falling back to CareX rehab engine if offline.
  Future<String> getResponse(String userQuery, {String? healthCondition}) async {
    if (_geminiModel != null) {
      try {
        final content = [Content.text(userQuery)];
        final response = await _geminiModel!.generateContent(content);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        // Fallback to local rehab engine on error/offline
      }
    }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate thinking delay

    final query = userQuery.toLowerCase();

    if (query.contains('neck') || query.contains('stiff')) {
      return "For neck stiffness:\n• Perform gentle Chin Tucks (10 reps)\n• Tilt your head side-to-side without forcing\n• Keep your monitor at eye level to prevent forward head posture.";
    } else if (query.contains('shoulder') || query.contains('desk')) {
      return "For shoulder tightness:\n• Do Cross-Body Shoulder Stretches (hold 20s each)\n• Roll shoulders backwards 10 times\n• Take a 2-minute stretch break every 45 minutes of desk work.";
    } else if (query.contains('wrist') || query.contains('mouse') || query.contains('typing')) {
      return "For wrist/carpal strain:\n• Extend your arm forward, gently pull fingers back for 15s\n• Use an ergonomic wrist pad\n• Avoid keeping wrists bent while typing.";
    } else if (query.contains('knee') || query.contains('squat')) {
      return "For knee joint comfort:\n• Keep knees aligned with toes during movement\n• Strengthen quadriceps with gentle straight leg raises\n• Avoid deep bending if experiencing discomfort.";
    } else if (query.contains('back') || query.contains('slouch') || query.contains('posture')) {
      return "To fix slouching & back pain:\n• Engage your core and keep your chest lifted\n• Adjust chair height so knees are at 90°\n• Perform Cat-Cow spine stretches twice daily.";
    }

    return "I am CareX AI Health Advisor! I am powered to give you personalized ergonomic tips, posture guidance, and stretching routines.\n\nAsk me about:\n1. Neck, Shoulder, Back, or Wrist relief\n2. Desk posture setup\n3. Pre-workout stretching techniques";
  }
}
