import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/vitals_chart.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  _HealthScreenState createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('ADAPTX');
  int? heartRate = 72;
  int? bloodOxygen = 98;
  bool isConnected = false;

  // Real timestamped vitals history dataset
  final List<VitalPoint> vitalHistory = [
    VitalPoint(timestamp: DateTime.now().subtract(const Duration(minutes: 15)), heartRate: 72, spO2: 98),
    VitalPoint(timestamp: DateTime.now().subtract(const Duration(minutes: 12)), heartRate: 75, spO2: 98),
    VitalPoint(timestamp: DateTime.now().subtract(const Duration(minutes: 9)), heartRate: 78, spO2: 97),
    VitalPoint(timestamp: DateTime.now().subtract(const Duration(minutes: 6)), heartRate: 74, spO2: 99),
    VitalPoint(timestamp: DateTime.now().subtract(const Duration(minutes: 3)), heartRate: 76, spO2: 98),
    VitalPoint(timestamp: DateTime.now(), heartRate: 73, spO2: 98),
  ];

  @override
  void initState() {
    super.initState();
    fetchRealTimeData();
  }

  void fetchRealTimeData() {
    databaseRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final newHR = int.tryParse(data['Blood_rate'].toString()) ?? 0;
        final newSpO2 = int.tryParse(data['Spo2'].toString()) ?? 0;

        if (mounted) {
          setState(() {
            isConnected = true;
            if (newHR > 0) heartRate = newHR;
            if (newSpO2 > 0) bloodOxygen = newSpO2;

            if (newHR > 0 && newSpO2 > 0) {
              vitalHistory.add(
                VitalPoint(
                  timestamp: DateTime.now(),
                  heartRate: newHR,
                  spO2: newSpO2,
                ),
              );
              if (vitalHistory.length > 20) {
                vitalHistory.removeAt(0);
              }
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hrStatus = _getHeartRateStatus(heartRate ?? 0);
    final spO2Status = _getSpO2Status(bloodOxygen ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate Navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Vitals & Health Analytics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'LIVE SYNC' : 'SIMULATED',
                  style: TextStyle(
                    color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 850;

            if (isDesktop) {
              // 2-Column Responsive Desktop / Web Layout
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Vitals Cards & Telemetry Info
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Real-Time Vitals Telemetry",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Live IoT hardware sensor feed via Firebase /ADAPTX",
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGlassmorphismCard(
                                  title: "Heart Rate",
                                  value: heartRate != null && heartRate! > 0 ? "$heartRate" : "--",
                                  unit: "BPM",
                                  icon: Icons.favorite_rounded,
                                  color: const Color(0xFFFF5252),
                                  statusLabel: hrStatus.$1,
                                  statusColor: hrStatus.$2,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildGlassmorphismCard(
                                  title: "Blood Oxygen",
                                  value: bloodOxygen != null && bloodOxygen! > 0 ? "$bloodOxygen" : "--",
                                  unit: "%",
                                  icon: Icons.water_drop_rounded,
                                  color: const Color(0xFF448AFF),
                                  statusLabel: spO2Status.$1,
                                  statusColor: spO2Status.$2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.health_and_safety_rounded, color: Colors.tealAccent, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Vitals Telemetry Status",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "Cardiovascular and SpO2 ranges are currently within optimal biometric parameters.",
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Column: Interactive Dual-Axis Chart
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VitalsHistoryChart(vitalPoints: vitalHistory),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile Single-Column Layout
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Real-Time Vitals",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Continuous IoT stream from ADAPTX telemetry",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassmorphismCard(
                          title: "Heart Rate",
                          value: heartRate != null && heartRate! > 0 ? "$heartRate" : "--",
                          unit: "BPM",
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFFFF5252),
                          statusLabel: hrStatus.$1,
                          statusColor: hrStatus.$2,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildGlassmorphismCard(
                          title: "Blood Oxygen",
                          value: bloodOxygen != null && bloodOxygen! > 0 ? "$bloodOxygen" : "--",
                          unit: "%",
                          icon: Icons.water_drop_rounded,
                          color: const Color(0xFF448AFF),
                          statusLabel: spO2Status.$1,
                          statusColor: spO2Status.$2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  VitalsHistoryChart(vitalPoints: vitalHistory),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, color: Colors.tealAccent, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Vitals Telemetry Status",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Cardiovascular and SpO2 ranges are currently within optimal biometric parameters.",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  (String, Color) _getHeartRateStatus(int hr) {
    if (hr == 0) return ("No Signal", Colors.grey);
    if (hr < 60) return ("Bradycardia", Colors.amberAccent);
    if (hr <= 100) return ("Optimal", Colors.greenAccent);
    return ("Elevated", Colors.redAccent);
  }

  (String, Color) _getSpO2Status(int spO2) {
    if (spO2 == 0) return ("No Signal", Colors.grey);
    if (spO2 >= 95) return ("Optimal", Colors.greenAccent);
    if (spO2 >= 90) return ("Mild Low", Colors.amberAccent);
    return ("Low Oxygen", Colors.redAccent);
  }

  Widget _buildGlassmorphismCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String statusLabel,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 0.8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

