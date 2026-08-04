/*import 'package:flutter/material.dart';
import 'home_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  _HealthScreenState createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int heartRate = 72; // Mock Heart Rate (Replace with IoT data)
  int bloodOxygen = 98; // Mock Blood Oxygen Level (Replace with IoT data)

  void showHealthInfo(String title, int value, String unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Your current $title is $value $unit'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Data"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Heart Rate Icon
                GestureDetector(
                  onTap: () => showHealthInfo("Heart Rate", heartRate, "BPM"),
                  child: Column(
                    children: [
                      Icon(Icons.favorite, size: 50, color: Colors.red),
                      const SizedBox(height: 10),
                      const Text("Heart Rate", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                // Blood Oxygen Icon
                GestureDetector(
                  onTap: () => showHealthInfo("Blood Oxygen", bloodOxygen, "%"),
                  child: Column(
                    children: [
                      Icon(Icons.bloodtype, size: 50, color: Colors.blue),
                      const SizedBox(height: 10),
                      const Text("Blood Oxygen", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*

//Correct one



import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  _HealthScreenState createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('ADAPTX');
  int? heartRate = 0;
  int? bloodOxygen = 0;

  @override
  void initState() {
    super.initState();
    fetchRealTimeData();
  }

  /*void fetchRealTimeData() {
    databaseRef.child("Blood_rate").onValue.listen((event) {
      final value = event.snapshot.value;
      print("Blood_rate from Firebase: $value");
      if (value != null) {
        setState(() {
          heartRate = int.tryParse(value.toString()) ?? 0;
        });
      }
    });

    databaseRef.child("Spo2").onValue.listen((event) {
      final value = event.snapshot.value;
      print("Spo2 from Firebase: $value");
      if (value != null) {
        setState(() {
          bloodOxygen = int.tryParse(value.toString()) ?? 0;
        });
      }
    });
  }*/

  void fetchRealTimeData() {
    databaseRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        print("Fetched Data: $data"); // Debug print
        setState(() {
          heartRate = int.tryParse(data['Blood_rate'].toString()) ?? 0;
          bloodOxygen = int.tryParse(data['Spo2'].toString()) ?? 0;
        });
      } else {
        print("No data available");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Data")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 5,
                      spreadRadius: 2)
                ],
              ),
              child: Column(
                children: [
                  const Text("Live Health Data",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.favorite,
                              size: 50, color: Colors.red),
                          const SizedBox(height: 10),
                          Text(
                            "Heart Rate: ${heartRate ?? 0} BPM",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.bloodtype,
                              size: 50, color: Colors.blue),
                          const SizedBox(height: 10),
                          Text(
                            "Blood Oxygen: ${bloodOxygen ?? 0}%",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => fetchRealTimeData(),
              child: const Text("Refresh Data"),
            ),
          ],
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  _HealthScreenState createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('ADAPTX');
  int? heartRate = 0;
  int? bloodOxygen = 0;

  @override
  void initState() {
    super.initState();
    fetchRealTimeData();
  }

  void fetchRealTimeData() {
    databaseRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        print("Fetched Data: $data");
        setState(() {
          heartRate = int.tryParse(data['Blood_rate'].toString()) ?? 0;
          bloodOxygen = int.tryParse(data['Spo2'].toString()) ?? 0;
        });
      } else {
        print("No data available");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Data")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Live Vitals",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildHealthCard(
                      title: "Heart Rate",
                      value: "${heartRate ?? 0}",
                      unit: "BPM",
                      icon: Icons.favorite,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildHealthCard(
                      title: "Blood Oxygen",
                      value: "${bloodOxygen ?? 0}",
                      unit: "%",
                      icon: Icons.bloodtype,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: ElevatedButton.icon(
                  onPressed: fetchRealTimeData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Data"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard({required String title, required String value, required String unit, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
