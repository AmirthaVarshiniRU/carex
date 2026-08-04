import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _surgeryTypeController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _currentMedicationsController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedRecoveryStage = 'Acute (0-2 weeks)';
  String _selectedInjuryType = 'None';
  
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _recoveryStages = ['Acute (0-2 weeks)', 'Sub-acute (2-6 weeks)', 'Rehabilitation (6+ weeks)'];
  final List<String> _injuryTypes = [
    'None', 
    'Fracture', 
    'Ligament Tear', 
    'Muscle Strain', 
    'Stroke',
    'Post-Surgery',
    'Spinal Injury',
    'Joint Replacement'
  ];

  bool _isSaving = false;

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;

        if (user != null) {
          // Create profile data
          final profileData = {
            'personalInfo': {
              'name': _nameController.text,
              'email': _emailController.text,
              'age': _ageController.text,
              'height': _heightController.text,
              'weight': _weightController.text,
              'gender': _selectedGender,
            },
            'rehabProfile': {
              'recoveryStage': _selectedRecoveryStage,
              'injuryType': _selectedInjuryType,
              'surgeryType': _surgeryTypeController.text,
              'medicalHistory': _medicalHistoryController.text,
              'currentMedications': _currentMedicationsController.text,
            },
            'profileCompleted': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          // Save to Firestore using set with merge
          print('Saving profile data to Firestore...');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(profileData, SetOptions(merge: true));
          print('Profile data saved successfully');

          // Navigate to home screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        } else {
          throw Exception('No user found');
        }
      } catch (e) {
        print('Error saving profile data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        "Create Your Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Personal Information Section
                          _buildSectionHeader("Personal Information"),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: "Full Name",
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Gender Selection
                          _buildSectionHeader("Gender"),
                          const SizedBox(height: 16),
                          _buildGenderSelector(),
                          const SizedBox(height: 24),
                          
                          // Body Metrics Section
                          _buildSectionHeader("Body Metrics"),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageController,
                                  label: "Age",
                                  icon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid age';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _heightController,
                                  label: "Height (cm)",
                                  icon: Icons.height_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid height';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  label: "Weight (kg)",
                                  icon: Icons.monitor_weight_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid weight';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Recovery Stage Section
                          _buildSectionHeader("Recovery Stage"),
                          const SizedBox(height: 16),
                          _buildRecoveryStageSelector(),
                          const SizedBox(height: 24),
                          
                          // Injury Type Section
                          _buildSectionHeader("Injury / Condition Type"),
                          const SizedBox(height: 16),
                          _buildInjuryTypeSelector(),
                          const SizedBox(height: 24),
                          
                          // Additional Medical Details
                          _buildSectionHeader("Additional Medical Details"),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _surgeryTypeController,
                            label: "Surgery Type (if any)",
                            icon: Icons.local_hospital_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _medicalHistoryController,
                            label: "Medical History",
                            icon: Icons.history,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _currentMedicationsController,
                            label: "Current Medications",
                            icon: Icons.medication_outlined,
                          ),
                          const SizedBox(height: 32),
                          
                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfileData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Complete Profile Setup',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF059669),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
  
  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: _genders.map((gender) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = gender;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedGender == gender
                      ? const Color(0xFF059669).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedGender == gender
                      ? Border.all(color: const Color(0xFF059669))
                      : null,
                ),
                child: Center(
                  child: Text(
                    gender,
                    style: TextStyle(
                      color: _selectedGender == gender
                          ? const Color(0xFF059669)
                          : Colors.grey.shade700,
                      fontWeight: _selectedGender == gender
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildRecoveryStageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _recoveryStages.map((stage) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRecoveryStage = stage;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: _selectedRecoveryStage == stage
                    ? const Color(0xFF059669).withOpacity(0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: stage != _recoveryStages.last
                        ? Colors.grey.shade300
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedRecoveryStage == stage
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _selectedRecoveryStage == stage
                        ? const Color(0xFF059669)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    stage,
                    style: TextStyle(
                      color: _selectedRecoveryStage == stage
                          ? const Color(0xFF059669)
                          : Colors.grey.shade700,
                      fontWeight: _selectedRecoveryStage == stage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildInjuryTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _injuryTypes.map((injury) {
        final isSelected = _selectedInjuryType == injury;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedInjuryType = injury;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF059669).withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF059669)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              injury,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF059669)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
