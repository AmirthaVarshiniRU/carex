import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

final DatabaseReference _healthRef = FirebaseDatabase.instance.ref('ADAPTX');
StreamSubscription<DatabaseEvent>? _healthSubscription;
int _currentHeartRate = 0;
int _currentSpO2 = 0;
bool _isHealthNormal = true;

class BreakPage extends StatefulWidget {
  final VoidCallback onBreakComplete;

  const BreakPage({super.key, required this.onBreakComplete});

  @override
  State<BreakPage> createState() => _BreakPageState();
}

class _BreakPageState extends State<BreakPage> {
  int _breakDuration = 0; // in seconds
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isTimerStarted = false;
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();
    _startHealthMonitoring();
  }

  void _startBreakTimer() {
    setState(() {
      _remainingSeconds = _breakDuration;
      _isTimerStarted = true;
      _alertShown = false; // Reset alert flag
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (_isHealthNormal) {
          widget.onBreakComplete();
          Navigator.pop(context);
        } else {
          if (!_alertShown) {
            _alertShown = true;
            _showPersistentHealthAlert();
          }
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _healthSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text("Break Timer")),
          appBar: AppBar(
      title: const Text("Break Timer"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          int popCount = 2;
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= popCount);
        },
      ),
    ),

      body: Center(
        child: !_isTimerStarted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Enter break duration (in seconds):"),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() => _breakDuration = int.tryParse(val) ?? 0);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'E.g. 30',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _breakDuration > 0 ? _startBreakTimer : null,
                    child: const Text("Start Break"),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 100.0,
                    lineWidth: 12.0,
                    percent:
                        (_remainingSeconds / _breakDuration).clamp(0.0, 1.0),
                    center: Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(fontSize: 28),
                    ),
                    progressColor: Colors.orange,
                    backgroundColor: Colors.grey[300]!,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _remainingSeconds > 0
                        ? "Break in progress..."
                        : "Completed!",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }

  void _startHealthMonitoring() {
    _healthSubscription = _healthRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        _currentHeartRate = int.tryParse(data['Blood_rate'].toString()) ?? 0;
        _currentSpO2 = int.tryParse(data['Spo2'].toString()) ?? 0;

        final isHeartRateNormal =
            _currentHeartRate >= 60 && _currentHeartRate <= 200;
        final isSpO2Normal = _currentSpO2 >= 90;

        setState(() {
          _isHealthNormal = isHeartRateNormal && isSpO2Normal;
        });
      }
    });
  }

  void _showPersistentHealthAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Health Alert'),
        content: Text(
          'Your heart rate is $_currentHeartRate BPM\n'
          'SpO2 is $_currentSpO2%\n'
          'Please wait until your vitals return to normal.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isTimerStarted = false;
                _timer?.cancel();
              });
            },
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }
}

