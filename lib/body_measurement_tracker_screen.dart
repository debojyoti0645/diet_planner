import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BodyMeasurementEntry {
  final DateTime date;
  final double waist;
  final double chest;
  final double arms;
  final double legs;
  final double hips;
  final double neck;
  final File? beforePhoto;
  final File? afterPhoto;

  BodyMeasurementEntry({
    required this.date,
    required this.waist,
    required this.chest,
    required this.arms,
    required this.legs,
    required this.hips,
    required this.neck,
    this.beforePhoto,
    this.afterPhoto,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'waist': waist,
    'chest': chest,
    'arms': arms,
    'legs': legs,
    'hips': hips,
    'neck': neck,
    'beforePhoto': beforePhoto?.path,
    'afterPhoto': afterPhoto?.path,
  };

  factory BodyMeasurementEntry.fromJson(Map<String, dynamic> json) =>
      BodyMeasurementEntry(
        date: DateTime.parse(json['date']),
        waist: (json['waist'] as num).toDouble(),
        chest: (json['chest'] as num).toDouble(),
        arms: (json['arms'] as num).toDouble(),
        legs: (json['legs'] as num).toDouble(),
        hips: (json['hips'] as num).toDouble(),
        neck: (json['neck'] as num).toDouble(),
        beforePhoto:
            json['beforePhoto'] != null && json['beforePhoto'] != ''
                ? File(json['beforePhoto'])
                : null,
        afterPhoto:
            json['afterPhoto'] != null && json['afterPhoto'] != ''
                ? File(json['afterPhoto'])
                : null,
      );
}

class BodyMeasurementTrackerScreen extends StatefulWidget {
  @override
  State<BodyMeasurementTrackerScreen> createState() =>
      _BodyMeasurementTrackerScreenState();
}

class _BodyMeasurementTrackerScreenState
    extends State<BodyMeasurementTrackerScreen> {
  final List<BodyMeasurementEntry> _entries = [];
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  double? _waist, _chest, _arms, _legs, _hips, _neck;

  // User data for ideal calculation
  double? _userHeight, _userWeight;
  int? _userAge;
  String? _userGender;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadUserData();
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entryList = _entries.map((e) => e.toJson()).toList();
    prefs.setString('body_measurements', jsonEncode(entryList));
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('body_measurements');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _entries.clear();
        _entries.addAll(decoded.map((e) => BodyMeasurementEntry.fromJson(e)));
      });
    }
  }

  void _addEntry() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _entries.add(
          BodyMeasurementEntry(
            date: _selectedDate,
            waist: _waist!,
            chest: _chest!,
            arms: _arms!,
            legs: _legs!,
            hips: _hips!,
            neck: _neck!,
          ),
        );
        _waist = _chest = _arms = _legs = _hips = _neck = null;
        _selectedDate = DateTime.now();
      });
      _saveEntries(); // Save after adding
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Example keys, adjust as per your dashboard storage
    _userHeight = prefs.getDouble('user_height');
    _userWeight = prefs.getDouble('user_weight');
    _userAge = prefs.getInt('user_age');
    _userGender = prefs.getString('user_gender');
    if (_userHeight == null ||
        _userWeight == null ||
        _userAge == null ||
        _userGender == null) {
      await _promptUserDataInput();
    }
    setState(() {});
  }

  Future<void> _promptUserDataInput() async {
    final formKey = GlobalKey<FormState>();
    double? height, weight;
    int? age;
    String? gender;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter Your Details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter height' : null,
                    onSaved: (v) => height = double.tryParse(v ?? ''),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter weight' : null,
                    onSaved: (v) => weight = double.tryParse(v ?? ''),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter age' : null,
                    onSaved: (v) => age = int.tryParse(v ?? ''),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    validator: (v) => v == null ? 'Select gender' : null,
                    onChanged: (v) => gender = v,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (height != null && weight != null && age != null && gender != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_height', height!);
      await prefs.setDouble('user_weight', weight!);
      await prefs.setInt('user_age', age!);
      await prefs.setString('user_gender', gender!);
      _userHeight = height;
      _userWeight = weight;
      _userAge = age;
      _userGender = gender;
    }
  }

  // Example: Calculate "ideal" measurements (replace with real formulas if needed)
  Map<String, double> _getIdealMeasurements() {
    if (_userHeight == null ||
        _userWeight == null ||
        _userAge == null ||
        _userGender == null) {
      return {};
    }
    // These are just example formulas, you can replace with real ones
    final h = _userHeight!;
    final g = _userGender!;
    return {
      'Waist': g == 'male' ? h * 0.43 : h * 0.42,
      'Chest': g == 'male' ? h * 0.53 : h * 0.50,
      'Arms': g == 'male' ? h * 0.16 : h * 0.15,
      'Legs': g == 'male' ? h * 0.29 : h * 0.28,
      'Hips': g == 'male' ? h * 0.46 : h * 0.54,
      'Neck': g == 'male' ? h * 0.13 : h * 0.12,
    };
  }

  Widget _buildIdealTable() {
    final ideals = _getIdealMeasurements();
    if (ideals.isEmpty) {
      return const Center(child: Text('User data missing.'));
    }
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(color: Colors.indigo.shade100),
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2)},
          children: [
            const TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Measurement',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Ideal Value (cm)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...ideals.entries.map(
              (e) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(e.key),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(e.value.toStringAsFixed(1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Body Measurement Tracker',
          style: TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
            child: Column(
              children: [
                _buildInputCard(context),
                const SizedBox(height: 24),
                Text(
                  'Ideal Measurements for You',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 8),
                _buildIdealTable(),
                const SizedBox(height: 24),
                _entries.isEmpty
                    ? _buildEmptyState()
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entries',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        ..._entries.reversed
                            .map((entry) => _buildEntryCard(entry))
                            .toList(),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(BuildContext context) {
    return Card(
      elevation: 10,
      shadowColor: Colors.indigo[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.09),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(18),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Color(0xFF6366F1),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Track Your Progress',
                      style: TextStyle(
                        color: const Color(0xFF6366F1),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log your body measurements and photos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF6366F1),
                ),
                title: Text(
                  "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildNumberField(
                    'Waist (cm)',
                    (v) => _waist = v,
                    Icons.straighten,
                  ),
                  _buildNumberField(
                    'Chest (cm)',
                    (v) => _chest = v,
                    Icons.accessibility_new,
                  ),
                  _buildNumberField(
                    'Arms (cm)',
                    (v) => _arms = v,
                    Icons.fitness_center,
                  ),
                  _buildNumberField(
                    'Legs (cm)',
                    (v) => _legs = v,
                    Icons.directions_run,
                  ),
                  _buildNumberField(
                    'Hips (cm)',
                    (v) => _hips = v,
                    Icons.directions_walk,
                  ),
                  _buildNumberField('Neck (cm)', (v) => _neck = v, Icons.face),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    Function(double) onSaved,
    IconData icon,
  ) {
    return SizedBox(
      width: 200,
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter $label';
          final v = double.tryParse(value);
          if (v == null || v <= 0) return 'Enter valid number';
          return null;
        },
        onSaved: (value) => onSaved(double.parse(value!)),
      ),
    );
  }

  Widget _buildEntryCard(BodyMeasurementEntry entry) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, color: Colors.indigo[400], size: 28),
              const SizedBox(height: 4),
              Text(
                '${entry.date.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Waist: ${entry.waist} cm, Chest: ${entry.chest} cm, Arms: ${entry.arms} cm',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legs: ${entry.legs} cm, Hips: ${entry.hips} cm, Neck: ${entry.neck} cm',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (entry.beforePhoto != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          entry.beforePhoto!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (entry.afterPhoto != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        entry.afterPhoto!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.insights, color: Colors.indigo[200], size: 60),
          const SizedBox(height: 16),
          Text(
            'No entries yet.',
            style: TextStyle(
              color: Colors.indigo[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start tracking your body measurements to see your progress over time!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
