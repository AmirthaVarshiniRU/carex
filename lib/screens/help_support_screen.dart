import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Getting Started',
                content: [
                  _buildFAQItem(
                    question: 'How do I start an exercise routine?',
                    answer: '1. Select your health condition from the home screen\n2. Choose your current mood\n3. The app will customize exercises based on your mood and health condition\n4. Follow the guided exercise routine with proper form and timing',
                  ),
                  _buildFAQItem(
                    question: 'What health conditions are supported?',
                    answer: 'We support various health conditions including:\n• Back pain\n• Joint issues\n• Cardiovascular conditions\n• Respiratory conditions\n• General fitness and wellness',
                  ),
                  _buildFAQItem(
                    question: 'How do I track my progress?',
                    answer: 'Your progress is automatically tracked in your profile:\n• Exercise history\n• Mood patterns\n• Duration and intensity\n• Achievement badges\n• Weekly and monthly statistics',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Exercise Features',
                content: [
                  _buildFAQItem(
                    question: 'How does mood-based exercise work?',
                    answer: 'The app analyzes your mood through:\n• Mood selection before exercises\n• Exercise intensity adjustments\n• Break duration modifications\n• Exercise type recommendations',
                  ),
                  _buildFAQItem(
                    question: 'Can I customize my workout?',
                    answer: 'Yes, you can customize:\n• Exercise duration\n• Break intervals\n• Exercise intensity\n• Number of repetitions\n• Exercise selection',
                  ),
                  _buildFAQItem(
                    question: 'What types of exercises are included?',
                    answer: 'We offer various exercise types:\n• Stretching\n• Strength training\n• Cardio\n• Balance exercises\n• Flexibility training\n• Low-impact options',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Contact Support',
                content: [
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@adapt2.com',
                    onTap: () => _launchEmail('support@adapt2.com'),
                  ),
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () => _launchPhone('+15551234567'),
                  ),
                  _buildContactItem(
                    icon: Icons.feedback,
                    title: 'Feedback',
                    subtitle: 'Share your thoughts and suggestions',
                    onTap: () => _launchFeedback(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Health & Safety',
                content: [
                  _buildEmergencyItem(
                    title: 'Emergency Contacts',
                    subtitle: 'Quick access to emergency services and contacts',
                    onTap: () => _showEmergencyContacts(context),
                  ),
                  _buildEmergencyItem(
                    title: 'Health Guidelines',
                    subtitle: 'Important health and safety information',
                    onTap: () => _showHealthGuidelines(context),
                  ),
                  _buildEmergencyItem(
                    title: 'Medical Disclaimer',
                    subtitle: 'Important information about exercise safety',
                    onTap: () => _showMedicalDisclaimer(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Account & Settings',
                content: [
                  _buildFAQItem(
                    question: 'How do I reset my password?',
                    answer: '1. Go to the login screen\n2. Tap "Forgot Password"\n3. Enter your email address\n4. Follow the instructions sent to your email',
                  ),
                  _buildFAQItem(
                    question: 'How do I update my profile?',
                    answer: '1. Go to your profile screen\n2. Tap the edit icon\n3. Update your information\n4. Save your changes',
                  ),
                  _buildFAQItem(
                    question: 'How do I change my preferences?',
                    answer: '1. Go to Settings\n2. Select "Preferences"\n3. Adjust your settings\n4. Save your changes',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Adapt2 Support Request',
        'body': 'Hello Adapt2 Support Team,\n\nI need help with:',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    }
  }


  void _launchFeedback() {
    // Implement feedback functionality
  }

  void _showEmergencyContacts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyContactItem('Emergency Services', '911'),
            _buildEmergencyContactItem('Poison Control', '1-800-222-1222'),
            _buildEmergencyContactItem('Local Hospital', 'Your local hospital number'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactItem(String title, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health Guidelines'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidelineItem(
                'Before Exercise',
                '• Warm up properly\n• Stay hydrated\n• Check your environment\n• Wear appropriate clothing',
              ),
              _buildGuidelineItem(
                'During Exercise',
                '• Listen to your body\n• Maintain proper form\n• Take breaks when needed\n• Stay hydrated',
              ),
              _buildGuidelineItem(
                'After Exercise',
                '• Cool down properly\n• Stretch\n• Rehydrate\n• Rest as needed',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  void _showMedicalDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'Before starting any exercise program:\n\n'
            '1. Consult with your healthcare provider\n'
            '2. Start slowly and gradually increase intensity\n'
            '3. Stop if you experience any pain or discomfort\n'
            '4. Listen to your body and take breaks when needed\n'
            '5. Stay hydrated and maintain proper nutrition\n\n'
            'This app is not a substitute for professional medical advice.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(height: 16),
        ...content,
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF059669),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmergencyItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.emergency,
            color: Colors.red,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
} 
