import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class VibrationTestScreen extends StatefulWidget {
  const VibrationTestScreen({super.key});

  @override 
  State<VibrationTestScreen> createState() => _VibrationTestScreenState();
}

class _VibrationTestScreenState extends State<VibrationTestScreen> {
  double _intensity = 0;
  bool _isVibrating = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _isVibrating = false;
    Vibration.cancel();
    super.dispose();
  }

  void _updateVibration(double value) {
    if (_isDisposed) return;
    
    Future.microtask(() {
      setState(() {
        _intensity = value;
      });

      if (value == 0) {
        Vibration.cancel();
        _isVibrating = false;
      } else {
        if (!_isVibrating) {
          _isVibrating = true;
          _startVibration();
        }
      }
    });
  }

  void _startVibration() async {
    while (_isVibrating && !_isDisposed) {
      await Vibration.vibrate(amplitude: (_intensity * 2.55).round());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Перевірка вібрації'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SleekCircularSlider(
                appearance: CircularSliderAppearance(
                  customColors: CustomSliderColors(
                    progressBarColor: Theme.of(context).colorScheme.primary,
                    trackColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    shadowColor: Colors.transparent,
                    dotColor: Theme.of(context).colorScheme.primary,
                  ),
                  size: 250,
                  startAngle: 150,
                  angleRange: 240,
                  counterClockwise: false,
                  spinnerMode: false,
                  animationEnabled: false,
                  customWidths: CustomSliderWidths(
                    trackWidth: 5,
                    progressBarWidth: 5,
                    shadowWidth: 0,
                    handlerSize: 10,
                  ),
                ),
                min: 0,
                max: 100,
                initialValue: _intensity,
                onChange: _updateVibration,
                innerWidget: (percentage) => Center(
                  child: Text(
                    '${percentage.round()}%',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _updateVibration(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Зупинити'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}