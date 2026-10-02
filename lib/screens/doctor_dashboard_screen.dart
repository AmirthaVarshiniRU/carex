import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/exercise_progress.dart';
import '../models/exercise_assignment.dart';
import '../models/patient_progress.dart';
import '../providers/auth_provider.dart';
import '../services/assignment_service.dart';
import '../services/exercise_catalog_service.dart';
import '../services/patient_progress_service.dart';
import '../services/progress_service.dart';
import 'exercise_page.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final ExerciseCatalogService _catalogService = ExerciseCatalogService();
  bool _catalogSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCatalog();
    });
  }

  Future<void> _syncCatalog() async {
    if (_catalogSyncing || !mounted) return;
    _catalogSyncing = true;
    try {
      await _catalogService.syncCatalog(ExercisePage.exerciseCatalog);
    } catch (e) {
      debugPrint('Exercise catalog sync failed: $e');
    } finally {
      if (mounted) _catalogSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = Provider.of<AuthProvider>(context).user;
    if (doctor == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doctor Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Manage patients',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showPatientMappingDialog(doctor.uid),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _assignmentService.watchPatients(doctor.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final patients = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _syncCatalog,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              children: [
                _header(doctor.displayName ?? 'Doctor', patients.length),
                const SizedBox(height: 20),
                if (patients.isEmpty)
                  _emptyPatients()
                else
                  ...patients.map((patient) => _patientCard(patient)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(String name, int patientCount) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $name', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$patientCount mapped patient${patientCount == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(Map<String, dynamic> patient) {
    final id = patient['id'] as String;
    final personal = (patient['personalInfo'] as Map?)?.cast<String, dynamic>() ?? {};
    final account = (patient['accountInfo'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = personal['name']?.toString().trim().isNotEmpty == true
        ? personal['name'].toString()
        : account['username']?.toString() ?? 'Patient';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: id, patientName: name))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(backgroundColor: Color(0xFFE8F5F1), child: Icon(Icons.person_rounded, color: Color(0xFF059669))),
                  const SizedBox(width: 14),
                  Expanded(child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
              StreamBuilder<List<ExerciseProgress>>(
                stream: ProgressService().watchUserProgress(id),
                builder: (context, progressStreamSnapshot) {
                  return FutureBuilder<PatientProgressSummary>(
                    future: PatientProgressService().getSummary(id),
                    builder: (context, progressSnapshot) {
                      final summary = progressSnapshot.data ?? PatientProgressSummary.empty;
                      return Row(
                        children: [
                          Expanded(child: _metric('Overall progress', '${summary.overallProgress.round()}%')),
                          Expanded(child: _metric('Compliance', '${summary.compliancePercentage.round()}%')),
                          Expanded(child: _metric('Form score', summary.averageFormScore > 0 ? '${summary.averageFormScore.round()}%' : '—')),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _emptyPatients() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: const Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 58, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('No patients mapped yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          SizedBox(height: 6),
          Text('Use the person-plus button to map a patient to your account.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _errorState(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load patients.\n$message', textAlign: TextAlign.center)));

  Future<void> _showPatientMappingDialog(String doctorId) async {
    final patients = await _assignmentService.getAllPatients();
    if (!mounted) return;
    String? selectedId;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Map patient'),
            content: patients.isEmpty
                ? const Text('No patient accounts exist yet.')
                : DropdownButtonFormField<String>(
                    value: selectedId,
                    decoration: const InputDecoration(labelText: 'Patient'),
                    items: patients.map((patient) {
                      final account = (patient['accountInfo'] as Map?)?.cast<String, dynamic>() ?? {};
                      final profile = (patient['personalInfo'] as Map?)?.cast<String, dynamic>() ?? {};
                      final name = profile['name']?.toString().trim().isNotEmpty == true
                          ? profile['name'].toString()
                          : account['username']?.toString() ?? 'Patient';
                      return DropdownMenuItem(value: patient['id'] as String, child: Text(name));
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedId = value),
                  ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: selectedId == null ? null : () async {
                  await _assignmentService.mapPatientToDoctor(patientId: selectedId!, doctorId: doctorId);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Map patient'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final PatientProgressService _progressService = PatientProgressService();
  final ProgressService _exerciseProgressService = ProgressService();

  @override
  Widget build(BuildContext context) {
    final doctorId = Provider.of<AuthProvider>(context).user?.uid;
    if (doctorId == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(widget.patientName)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Assign exercise'),
        onPressed: () => _showAssignDialog(doctorId),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          StreamBuilder<List<ExerciseProgress>>(
            stream: _exerciseProgressService.watchUserProgress(widget.patientId),
            builder: (context, progressSnapshot) {
              return FutureBuilder<PatientProgressSummary>(
                future: _progressService.getSummary(widget.patientId),
                builder: (context, snapshot) => _summaryCard(snapshot.data ?? PatientProgressSummary.empty),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text('Assigned exercises', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          StreamBuilder<List<ExerciseAssignment>>(
            stream: _assignmentService.watchDoctorAssignments(doctorId),
            builder: (context, snapshot) {
              final assignments = (snapshot.data ?? []).where((a) => a.patientId == widget.patientId && a.status != 'cancelled').toList();
              if (assignments.isEmpty) return _emptyCard('No exercises assigned yet.');
              return Column(children: assignments.map(_assignmentCard).toList());
            },
          ),
          const SizedBox(height: 18),
          const Text('Exercise history', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          StreamBuilder<List<ExerciseProgress>>(
            stream: _exerciseProgressService.watchUserProgress(widget.patientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final items = snapshot.data ?? [];
              if (items.isEmpty) return _emptyCard('No exercise sessions recorded yet.');
              return Column(children: items.take(20).map(_historyCard).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(PatientProgressSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall rehabilitation progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('${summary.overallProgress.round()}%', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900))),
            Text('${summary.completedAssignedExercises}/${summary.totalAssignedExercises} exercises', style: const TextStyle(color: Colors.white70)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: summary.overallProgress / 100, minHeight: 10, backgroundColor: Colors.white12, color: Colors.tealAccent)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _darkMetric('Sessions', '${summary.totalSessions}')),
            Expanded(child: _darkMetric('Compliance', '${summary.compliancePercentage.round()}%')),
            Expanded(child: _darkMetric('Form', summary.averageFormScore > 0 ? '${summary.averageFormScore.round()}%' : '—')),
          ]),
        ],
      ),
    );
  }

  Widget _darkMetric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))]);

  Widget _assignmentCard(ExerciseAssignment assignment) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5F1), child: Icon(Icons.fitness_center_rounded, color: Color(0xFF059669))),
        title: Text(assignment.exerciseName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${assignment.targetReps} reps × ${assignment.targetSets} set${assignment.targetSets == 1 ? '' : 's'} • ${assignment.status}\n${assignment.doctorNotes.isEmpty ? 'No doctor notes' : assignment.doctorNotes}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'cancel') await _assignmentService.cancelAssignment(assignment.id);
          },
          itemBuilder: (_) => const [PopupMenuItem(value: 'cancel', child: Text('Cancel assignment'))],
        ),
      ),
    );
  }

  Widget _historyCard(ExerciseProgress progress) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(progress.exerciseName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${progress.completedReps}/${progress.targetReps} reps • ${progress.date.day}/${progress.date.month}/${progress.date.year}'),
        trailing: progress.formScore > 0 ? Text('${progress.formScore}% form', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700)) : null,
      ),
    );
  }

  Widget _emptyCard(String text) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Text(text, style: const TextStyle(color: Colors.grey)));

  Future<void> _showAssignDialog(String doctorId) async {
    final allExercises = ExercisePage.exerciseCatalog;
    if (allExercises.isEmpty) return;

    final categories = allExercises.map((e) => e.category).toSet().toList();
    String selectedCategory = categories.first;
    List<Exercise> exercises = allExercises
        .where((e) => e.category == selectedCategory)
        .toList();
    Exercise selected = exercises.first;
    final repsController = TextEditingController(text: selected.reps.toString());
    final notesController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Assign to ${widget.patientName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Rehab category'),
                    items: categories
                        .map((category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedCategory = value;
                        exercises = allExercises
                            .where((e) => e.category == value)
                            .toList();
                        selected = exercises.first;
                        repsController.text = selected.reps.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Exercise>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Exercise'),
                    items: exercises
                        .map((exercise) => DropdownMenuItem<Exercise>(
                              value: exercise,
                              child: Text(exercise.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selected = value;
                          repsController.text = value.reps.toString();
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target reps'),
                  ),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Doctor notes'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Start: ${startDate.day}/${startDate.month}/${startDate.year}')),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: startDate,
                          );
                          if (date != null) setState(() => startDate = date);
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(endDate == null ? 'No end date' : 'End: ${endDate!.day}/${endDate!.month}/${endDate!.year}')),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: endDate ?? startDate,
                          );
                          if (date != null) setState(() => endDate = date);
                        },
                        child: const Text('Set end'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final reps = int.tryParse(repsController.text) ?? selected.reps;
                  if (reps <= 0) return;

                  try {
                    await _assignmentService.createAssignment(
                      doctorId: doctorId,
                      patientId: widget.patientId,
                      exerciseId: selected.id,
                      exerciseName: selected.name,
                      category: selectedCategory,
                      targetReps: reps,
                      targetSets: 1,
                      startDate: startDate,
                      endDate: endDate,
                      doctorNotes: notesController.text.trim(),
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Could not assign exercise: $e')),
                      );
                    }
                  }
                },
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );

    repsController.dispose();
    notesController.dispose();
  }
}
