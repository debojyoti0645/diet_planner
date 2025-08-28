import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SportsStopwatchScreen extends StatefulWidget {
  const SportsStopwatchScreen({super.key});

  @override
  State<SportsStopwatchScreen> createState() => _SportsStopwatchScreenState();
}

class _SportsStopwatchScreenState extends State<SportsStopwatchScreen>
    with TickerProviderStateMixin {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsed = "00:00.00";
  final List<LapData> _laps = [];

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;

  // Sports-specific features
  int _targetLaps = 10;
  Duration? _targetTime;
  String _selectedSport = 'General';
  bool _autoLapMode = false;
  Duration _autoLapInterval = const Duration(minutes: 1);

  // Vibration patterns
  bool _hapticsEnabled = true;
  double _currentPace = 0.0; // seconds per lap
  LapData? _bestLap;
  LapData? _worstLap;

  // Sound and visual feedback
  bool _soundEnabled = true;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => _updateTime(),
    );

    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  void _updateTime() {
    if (_stopwatch.isRunning) {
      final elapsed = _stopwatch.elapsed;
      setState(() {
        _elapsed = _formatTime(elapsed);
      });

      // Update rotation based on seconds
      _rotationController.value = (elapsed.inMilliseconds % 60000) / 60000;

      // Auto-lap functionality
      if (_autoLapMode &&
          elapsed.inMilliseconds > 0 &&
          elapsed.inMilliseconds % _autoLapInterval.inMilliseconds == 0) {
        _recordLap();
      }

      // Check for target achievements
      _checkTargets();
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((duration.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return "$minutes:$seconds.$centiseconds";
  }

  void _checkTargets() {
    // Target laps reached
    if (_laps.length == _targetLaps && !_flashController.isAnimating) {
      _triggerAchievement("Target laps reached! 🎯");
    }

    // Target time reached
    if (_targetTime != null &&
        _stopwatch.elapsed >= _targetTime! &&
        !_flashController.isAnimating) {
      _triggerAchievement("Target time reached! ⏰");
    }

    // New best lap
    if (_laps.isNotEmpty &&
        (_bestLap == null || _laps.last.duration < _bestLap!.duration)) {
      _bestLap = _laps.last;
      _triggerAchievement("New best lap! ⚡");
    }
  }

  void _triggerAchievement(String message) {
    _flashController.forward().then((_) => _flashController.reverse());
    if (_hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _startStopwatch() {
    setState(() {
      _stopwatch.start();
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    });
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _pauseStopwatch() {
    setState(() {
      _stopwatch.stop();
      _pulseController.stop();
      _rotationController.stop();
    });
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _elapsed = "00:00.00";
      _laps.clear();
      _bestLap = null;
      _worstLap = null;
      _currentPace = 0.0;
      _pulseController.reset();
      _rotationController.reset();
    });
    if (_hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void _recordLap() {
    if (_stopwatch.isRunning) {
      final lapTime = _stopwatch.elapsed;
      final lapDuration =
          _laps.isEmpty
              ? lapTime
              : lapTime -
                  _laps
                      .map((l) => l.duration)
                      .fold(Duration.zero, (a, b) => a + b);

      final lap = LapData(
        number: _laps.length + 1,
        time: _elapsed,
        duration: lapDuration,
        totalDuration: lapTime,
        pace: _calculatePace(lapDuration),
      );

      setState(() {
        _laps.insert(0, lap);
        _currentPace = lap.pace;

        // Update best/worst laps
        if (_bestLap == null || lapDuration < _bestLap!.duration) {
          _bestLap = lap;
        }
        if (_worstLap == null || lapDuration > _worstLap!.duration) {
          _worstLap = lap;
        }
      });

      // Enhanced haptic feedback based on performance
      if (_hapticsEnabled) {
        if (_laps.length > 1) {
          final previousLap = _laps[1];
          if (lapDuration < previousLap.duration) {
            HapticFeedback.lightImpact(); // Faster lap
          } else {
            HapticFeedback.mediumImpact(); // Slower lap
          }
        } else {
          HapticFeedback.selectionClick();
        }
      }

      _flashController.forward().then((_) => _flashController.reverse());
    }
  }

  double _calculatePace(Duration lapDuration) {
    return lapDuration.inMilliseconds / 1000.0; // seconds per lap
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildHeader(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildMainTimer(),
                    const SizedBox(height: 18),
                    _buildControls(),
                    const SizedBox(height: 12),
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    _buildLapsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Stopwatch",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _selectedSport,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_targetLaps > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "${_laps.length}/$_targetLaps laps",
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                _getIconForSport(_selectedSport),
                color: Colors.white.withOpacity(0.7),
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainTimer() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _flashController,
        _waveController,
      ]),
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final flashValue = _flashController.value;
        final waveValue = _waveController.value;

        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF4CAF50,
                ).withOpacity(0.4 + flashValue * 0.2),
                blurRadius: 30 + pulseValue * 20,
                spreadRadius: 5 + pulseValue * 10,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated wave background
              // CustomPaint(
              //   size: const Size(280, 280),
              //   painter: WavePainter(waveValue, _stopwatch.isRunning),
              // ),
              // Circular progress
              SizedBox(
                width: 250,
                height: 250,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _rotationController.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          const Color(0xFF4CAF50),
                          const Color(0xFF2196F3),
                          sin(waveValue * 2 * pi) * 0.5 + 0.5,
                        )!,
                      ),
                    );
                  },
                ),
              ),
              // Time display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _elapsed,
                    key: ValueKey(_elapsed),
                    style: TextStyle(
                      fontFamily: 'Roboto Mono',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SportButton(
          icon: Icons.flag_rounded,
          label: "LAP",
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: _recordLap,
          enabled: _stopwatch.isRunning,
          size: 70,
        ),
        _SportButton(
          icon:
              _stopwatch.isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
          label: _stopwatch.isRunning ? "PAUSE" : "START",
          gradient:
              _stopwatch.isRunning
                  ? const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          onTap: _stopwatch.isRunning ? _pauseStopwatch : _startStopwatch,
          size: 75,
        ),
        _SportButton(
          icon: Icons.restart_alt_rounded,
          label: "RESET",
          gradient: const LinearGradient(
            colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: _resetStopwatch,
          enabled: _stopwatch.isRunning || _stopwatch.elapsedMilliseconds > 0,
          size: 70,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    if (_laps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: "Best Lap",
            value: _bestLap != null ? _formatTime(_bestLap!.duration) : "--:--",
            color: const Color(0xFF4CAF50),
          ),
          _StatItem(
            label: "Worst Lap",
            value:
                _worstLap != null ? _formatTime(_worstLap!.duration) : "--:--",
            color: const Color(0xFFF44336),
          ),
          _StatItem(
            label: "Avg Pace",
            value:
                _laps.isNotEmpty
                    ? "${(_laps.map((l) => l.pace).reduce((a, b) => a + b) / _laps.length).toStringAsFixed(2)}s"
                    : "--.-s",
            color: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildLapsList() {
    if (_laps.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Start timing to record laps",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _laps.length,
        itemBuilder: (context, index) {
          final lap = _laps[index];
          final isCurrentBest = lap == _bestLap;
          final isCurrentWorst = lap == _worstLap;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isCurrentBest
                        ? const Color(0xFF4CAF50)
                        : isCurrentWorst
                        ? const Color(0xFFF44336)
                        : Colors.white12,
                width: isCurrentBest || isCurrentWorst ? 2 : 1,
              ),
              boxShadow: [
                if (isCurrentBest || isCurrentWorst)
                  BoxShadow(
                    color: (isCurrentBest
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336))
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors:
                        isCurrentBest
                            ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
                            : isCurrentWorst
                            ? [const Color(0xFFF44336), const Color(0xFFD32F2F)]
                            : [Colors.white24, Colors.white12],
                  ),
                ),
                child: Center(
                  child: Text(
                    "${lap.number}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(lap.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                  if (isCurrentBest || isCurrentWorst)
                    Icon(
                      isCurrentBest ? Icons.star : Icons.trending_down,
                      color:
                          isCurrentBest
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                      size: 20,
                    ),
                ],
              ),
              subtitle: Text(
                "Pace: ${lap.pace.toStringAsFixed(2)}s | Total: ${lap.time}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForSport(String sport) {
    switch (sport) {
      case 'Running':
        return Icons.directions_run;
      case 'Swimming':
        return Icons.pool;
      case 'Cycling':
        return Icons.pedal_bike;
      case 'Boxing':
        return Icons.sports_mma;
      default:
        return Icons.timer;
    }
  }
}

class LapData {
  final int number;
  final String time;
  final Duration duration;
  final Duration totalDuration;
  final double pace;

  LapData({
    required this.number,
    required this.time,
    required this.duration,
    required this.totalDuration,
    required this.pace,
  });
}

class _SportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool enabled;
  final double size;

  const _SportButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.enabled = true,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: enabled ? onTap : null,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: size * 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isRunning;

  WavePainter(this.animationValue, this.isRunning);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRunning) return;

    final paint =
        Paint()
          ..color = const Color(0xFF4CAF50).withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final radius =
          maxRadius * 0.3 + (maxRadius * 0.4 * (animationValue + i * 0.3) % 1);
      final opacity = 1.0 - (animationValue + i * 0.3) % 1;

      paint.color = const Color(0xFF4CAF50).withOpacity(opacity * 0.3);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
