import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

class MedicationService {
  static const String _storageKey = 'carex_medications_list';

  /// Loads list of saved medications from SharedPreferences. Pre-seeds with defaults if empty.
  Future<List<Medication>> getMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_storageKey);

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawJson);
        return decoded.map((item) => Medication.fromMap(item)).toList();
      } catch (e) {
        debugPrint('Error decoding medications: $e');
      }
    }

    // Default pre-seeded realistic medication schedule
    final defaultMeds = [
      Medication(
        id: '1',
        name: 'Posture Stretch & Vitamin D3',
        dosage: '1000 IU',
        time: const TimeOfDay(hour: 9, minute: 0),
        isTaken: true,
        category: 'Supplements',
      ),
      Medication(
        id: '2',
        name: 'Omega-3 Joint Care',
        dosage: '1 Capsule',
        time: const TimeOfDay(hour: 13, minute: 30),
        isTaken: false,
        category: 'Joint Health',
      ),
      Medication(
        id: '3',
        name: 'Magnesium Muscle Relaxant',
        dosage: '200 mg',
        time: const TimeOfDay(hour: 21, minute: 0),
        isTaken: false,
        category: 'Recovery',
      ),
    ];

    await saveMedications(defaultMeds);
    return defaultMeds;
  }

  Future<void> saveMedications(List<Medication> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(list.map((m) => m.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<Medication>> addMedication(Medication medication) async {
    final current = await getMedications();
    current.add(medication);
    await saveMedications(current);
    return current;
  }

  Future<List<Medication>> toggleTaken(String id) async {
    final current = await getMedications();
    for (final med in current) {
      if (med.id == id) {
        med.isTaken = !med.isTaken;
        break;
      }
    }
    await saveMedications(current);
    return current;
  }

  Future<List<Medication>> deleteMedication(String id) async {
    final current = await getMedications();
    current.removeWhere((m) => m.id == id);
    await saveMedications(current);
    return current;
  }
}
