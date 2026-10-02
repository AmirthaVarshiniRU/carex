import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioCountdownTimer extends StatefulWidget {
  final int duration;
  final Function() onComplete;
  final CountDownController? controller;
  final bool autoStart;

  const AudioCountdownTimer({
    Key? key,
    required this.duration,
    required this.onComplete,
    this.controller,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<AudioCountdownTimer> createState() => _AudioCountdownTimerState();
}

class _AudioCountdownTimerState extends State<AudioCountdownTimer> {
  late AudioPlayer _audioPlayer;
  bool _isSoundEnabled = true;
  int _lastPlayedSecond = -1;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadSoundPreference();
    _remainingSeconds = widget.duration;
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundEnabled = prefs.getBool('countdown_sound_enabled') ?? true;
    });
  }

  Future<void> _saveSoundPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('countdown_sound_enabled', value);
    setState(() {
      _isSoundEnabled = value;
    });
  }

  void _playCountdownSound(int remainingSeconds) async {
    if (!_isSoundEnabled || remainingSeconds == _lastPlayedSecond) return;

    _lastPlayedSecond = remainingSeconds;

    if (remainingSeconds <= 3 && remainingSeconds > 0) {
      // Play beep sound for last 3 seconds
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
    } else if (remainingSeconds == 0) {
      // Play completion sound
      await _audioPlayer.play(AssetSource('audio/complete.mp3'));
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularCountDownTimer(
          duration: widget.duration,
          initialDuration: 0,
          controller: widget.controller,
          width: 100,
          height: 100,
          ringColor: Colors.grey[300]!,
          fillColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          strokeWidth: 10.0,
          strokeCap: StrokeCap.round,
          textStyle: const TextStyle(
            fontSize: 24.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textFormat: CountdownTextFormat.S,
          isReverse: true,
          isReverseAnimation: true,
          isTimerTextShown: true,
          autoStart: widget.autoStart,
          onComplete: widget.onComplete,
          timeFormatterFunction: (defaultFormattedTime, duration) {
            return _formatTime(duration.inSeconds);
          },
          onChange: (timeStamp) {
            try {
              final seconds = widget.duration - int.parse(timeStamp);
              setState(() {
                _remainingSeconds = seconds;
              });
              _playCountdownSound(seconds);
            } catch (e) {
              print('Error parsing timestamp: $e');
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sound'),
            Switch(
              value: _isSoundEnabled,
              onChanged: _saveSoundPreference,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ],
    );
  }
}
