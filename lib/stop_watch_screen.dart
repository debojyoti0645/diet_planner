import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart'; // Core Flutter widgets
import 'package:flutter/services.dart'; // For HapticFeedback

// Main StatefulWidget for the Stopwatch Screen
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

// State class for StopwatchScreen, with TickerProviderStateMixin for animations
class _StopwatchScreenState extends State<StopwatchScreen> with TickerProviderStateMixin {
  final Stopwatch _stopwatch = Stopwatch(); // The actual stopwatch logic
  late Timer _timer; // Timer to update the UI
  String _elapsed = "00:00:00"; // Formatted elapsed time string
  final List<String> _laps = []; // List to store lap times
  late AnimationController _controller; // Controller for the circular progress animation

  @override
  void initState() {
    super.initState();
    // Initialize the timer to update the UI every 100 milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateTime());
    // Initialize the animation controller for a 60-second duration cycle
    _controller = AnimationController(
      vsync: this, // TickerProvider for the animation
      duration: const Duration(seconds: 60), // One full rotation per minute
    );
  }

  // Method to update the elapsed time and the animation controller's value
  void _updateTime() {
    if (_stopwatch.isRunning) {
      final elapsed = _stopwatch.elapsed; // Get current elapsed duration
      // Update the UI with the formatted time
      setState(() {
        _elapsed =
            "${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}";
      });
      // Update the animation controller value based on elapsed milliseconds within a minute
      _controller.value = (elapsed.inMilliseconds % 60000) / 60000;
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    _controller.dispose(); // Dispose the animation controller
    super.dispose();
  }

  // Method to start the stopwatch
  void _startStopwatch() {
    setState(() {
      _stopwatch.start(); // Start the stopwatch
      _controller.repeat(); // Start repeating the animation
    });
  }

  // Method to stop (pause) the stopwatch
  void _stopStopwatch() {
    setState(() {
      _stopwatch.stop(); // Stop the stopwatch
      _controller.stop(); // Stop the animation
    });
  }

  // Method to reset the stopwatch
  void _resetStopwatch() {
    setState(() {
      _stopwatch.stop(); // Stop the stopwatch
      _stopwatch.reset(); // Reset the elapsed time
      _elapsed = "00:00:00"; // Reset displayed time
      _laps.clear(); // Clear all recorded laps
      _controller.value = 0; // Reset animation controller value
      _controller.stop(); // Stop the animation
    });
  }

  // Method to record a lap time
  void _lap() async {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _elapsed); // Add current elapsed time as a new lap (at the beginning)
      });
      try {
        HapticFeedback.mediumImpact(); // Provide haptic feedback on lap
      } catch (_) {
        // Handle potential errors if haptic feedback is not supported
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set a dark, deep background color for a gym app feel
      backgroundColor: const Color(0xFF1A1A2E), // Darker, more saturated background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent app bar
        elevation: 0, // No shadow under app bar
        title: const Text(
          "Stopwatch",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular progress indicator and time display
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250, // Slightly larger
                    height: 250,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _controller.value, // Animation value for progress
                          strokeWidth: 12, // Thicker stroke
                          backgroundColor: Colors.grey.shade800.withOpacity(0.5), // Semi-transparent background
                          // Gradient for the progress indicator
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)), // Vibrant green
                        );
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300), // Smooth transition for time change
                    child: Text(
                      _elapsed,
                      key: ValueKey(_elapsed), // Key for AnimatedSwitcher to identify changes
                      style: const TextStyle(
                        fontFamily: 'Montserrat', // A more modern, clean font
                        fontSize: 52, // Larger font size
                        fontWeight: FontWeight.w900, // Extra bold
                        color: Colors.white,
                        letterSpacing: 3, // Increased letter spacing for readability
                        shadows: [
                          // Subtle text shadow for depth
                          Shadow(
                            blurRadius: 10.0,
                            color: Color(0xFF4CAF50), // Green glow
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48), // Increased spacing
              // Modern control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GradientCircleButton(
                    icon: Icons.flag_rounded, // Rounded flag icon
                    tooltip: "Lap",
                    // Gradient for Lap button
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)], // Blue gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _lap,
                    enabled: _stopwatch.isRunning, // Only enabled when stopwatch is running
                  ),
                  const SizedBox(width: 28), // Increased spacing
                  _GradientCircleButton(
                    icon: _stopwatch.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, // Play/Pause icon
                    tooltip: _stopwatch.isRunning ? "Pause" : "Start",
                    // Conditional gradient based on stopwatch state
                    gradient: _stopwatch.isRunning
                        ? const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)], // Orange gradient for pause
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)], // Green gradient for play
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    onTap: _stopwatch.isRunning ? _stopStopwatch : _startStopwatch,
                    size: 70, // Larger button for start/pause
                  ),
                  const SizedBox(width: 28), // Increased spacing
                  _GradientCircleButton(
                    icon: Icons.stop_rounded, // Rounded stop icon
                    tooltip: "Reset",
                    // Gradient for Reset button
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF44336), Color(0xFFD32F2F)], // Red gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _resetStopwatch,
                    // Enabled if running or if time has elapsed
                    enabled: _stopwatch.isRunning || _stopwatch.elapsedMilliseconds > 0,
                  ),
                ],
              ),
              const SizedBox(height: 48), // Increased spacing
              // Lap list
              Expanded(
                child: _laps.isEmpty
                    ? const Center(
                        child: Text(
                          "No laps recorded yet",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ScrollConfiguration(
                        // Remove glow on scroll
                        behavior: const ScrollBehavior().copyWith(overscroll: false),
                        child: ListView.builder(
                          itemCount: _laps.length,
                          itemBuilder: (context, i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6), // More vertical padding
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08), // Slightly more opaque background
                                  borderRadius: BorderRadius.circular(15), // More rounded corners
                                  border: Border.all(color: Colors.white12, width: 0.8), // Subtle border
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Text(
                                    "Lap ${_laps.length - i}", // Display lap number in ascending order
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: Text(
                                    _laps[i],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20, // Larger font for lap time
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom button widget with gradient background for a modern look
class _GradientCircleButton extends StatelessWidget {
  final IconData icon; // Icon to display
  final String tooltip; // Tooltip text
  final Gradient gradient; // Gradient for the button background
  final VoidCallback onTap; // Callback when button is tapped
  final bool enabled; // Whether the button is enabled
  final double size; // Size of the button

  const _GradientCircleButton({
    required this.icon,
    required this.tooltip,
    required this.gradient,
    required this.onTap,
    this.enabled = true,
    this.size = 60, // Default size for buttons
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4, // Reduce opacity if disabled
      child: Material(
        color: Colors.transparent, // Make Material transparent
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(size / 2), // Half of size for perfect circle
            onTap: enabled ? onTap : null, // Disable tap if not enabled
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient, // Apply the gradient
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4), // Shadow based on gradient color
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Inner shadow for depth
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5), // Subtle white border
              ),
              child: Icon(
                icon,
                color: Colors.white, // White icon color
                size: size * 0.45, // Icon size relative to button size
              ),
            ),
          ),
        ),
      ),
    );
  }
}
