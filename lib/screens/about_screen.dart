import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
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
              _buildAppInfo(),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Our Mission',
                content: 'CAREX is dedicated to providing personalized exercise routines that adapt to your health conditions. We believe in making fitness accessible and enjoyable for everyone, regardless of their current state of health.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Features',
                content: [
                  _buildFeatureItem(
                    icon: Icons.mood,
                    title: 'Mood-Based Exercises',
                    description: 'Exercises that adapt to your current mood and energy levels.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.favorite,
                    title: 'Health-Focused',
                    description: 'Customized routines for various health conditions.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.timer,
                    title: 'Flexible Duration',
                    description: 'Adjustable exercise and break durations.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.trending_up,
                    title: 'Progress Tracking',
                    description: 'Monitor your fitness journey and mood patterns.',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Privacy & Security',
                content: 'We take your privacy seriously. All personal information and health data are securely stored and encrypted. We never share your data with third parties without your explicit consent.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Terms of Service',
                content: 'By using CAREX, you agree to our terms of service. Please consult with your healthcare provider before starting any exercise program.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Version Information',
                content: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      );
                    }
                    return const Text('Loading version information...');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 50,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CAREX',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Personal Fitness Companion',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required dynamic content,
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
        if (content is String)
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          )
        else if (content is List<Widget>)
          ...content,
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
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
          description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }
} 