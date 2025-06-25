import 'package:diet_planner/body_measurement_tracker_screen.dart';
import 'package:diet_planner/calorie_burned_estimator.dart';
import 'package:diet_planner/home_screen.dart';
import 'package:diet_planner/stop_watch_screen.dart';
import 'package:diet_planner/water_intake_calculator.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personalized Health Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF60A5FA),
          background: const Color(0xFFF3F4F6),
          surface: Colors.white,
        ),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF312E81),
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFF6366F1)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 50.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF312E81),
          ),
          titleLarge: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4338CA),
          ),
          titleMedium: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF312E81),
          ),
          bodyMedium: TextStyle(fontSize: 15.0, color: Color(0xFF374151)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
            borderSide: BorderSide(color: Color(0xFF6366F1), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 14.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
            elevation: 6.0,
            shadowColor: Colors.indigoAccent.withOpacity(0.2),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.85),
          elevation: 8,
          shadowColor: Colors.indigo.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Color(0xFF9CA3AF),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/stopwatch': (context) => const StopwatchScreen(),
        '/body_measurement': (context) => BodyMeasurementTrackerScreen(),
        '/calorie_burned_estimator': (context) => CalorieBurnedEstimator(),
        '/water_intake_calculator': (context) => WaterIntakeCalculator(),
        // Add more routes if needed
      },
    );
  }
}
