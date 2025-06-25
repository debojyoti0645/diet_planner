import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _beforePhoto, _afterPhoto;

  Future<void> _pickPhoto(bool isBefore) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isBefore) {
          _beforePhoto = File(picked.path);
        } else {
          _afterPhoto = File(picked.path);
        }
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
            beforePhoto: _beforePhoto,
            afterPhoto: _afterPhoto,
          ),
        );
        _waist = _chest = _arms = _legs = _hips = _neck = null;
        _beforePhoto = _afterPhoto = null;
        _selectedDate = DateTime.now();
      });
    }
  }

  List<FlSpot> _getSpots(String measurement) {
    List<FlSpot> spots = [];
    _entries.sort((a, b) => a.date.compareTo(b.date));
    for (int i = 0; i < _entries.length; i++) {
      double value;
      switch (measurement) {
        case 'Waist':
          value = _entries[i].waist;
          break;
        case 'Chest':
          value = _entries[i].chest;
          break;
        case 'Arms':
          value = _entries[i].arms;
          break;
        case 'Legs':
          value = _entries[i].legs;
          break;
        case 'Hips':
          value = _entries[i].hips;
          break;
        case 'Neck':
          value = _entries[i].neck;
          break;
        default:
          value = 0;
      }
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
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
                _entries.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress Graphs',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6366F1),
                                ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(height: 220, child: _buildGraphTabs()),
                          const SizedBox(height: 24),
                          Text(
                            'Entries',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                leading: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
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
                  _buildNumberField('Waist (cm)', (v) => _waist = v, Icons.straighten),
                  _buildNumberField('Chest (cm)', (v) => _chest = v, Icons.accessibility_new),
                  _buildNumberField('Arms (cm)', (v) => _arms = v, Icons.fitness_center),
                  _buildNumberField('Legs (cm)', (v) => _legs = v, Icons.directions_run),
                  _buildNumberField('Hips (cm)', (v) => _hips = v, Icons.directions_walk),
                  _buildNumberField('Neck (cm)', (v) => _neck = v, Icons.face),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoColumn(
                    label: 'Before Photo',
                    file: _beforePhoto,
                    onTap: () => _pickPhoto(true),
                  ),
                  _buildPhotoColumn(
                    label: 'After Photo',
                    file: _afterPhoto,
                    onTap: () => _pickPhoto(false),
                  ),
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

  Widget _buildNumberField(String label, Function(double) onSaved, IconData icon) {
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

  Widget _buildPhotoColumn({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1),
                width: 1.2,
              ),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      file,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: Color(0xFF6366F1), size: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphTabs() {
    final measurements = ['Waist', 'Chest', 'Arms', 'Legs', 'Hips', 'Neck'];
    return DefaultTabController(
      length: measurements.length,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.97),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 4, right: 4, bottom: 4),
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: const Color(0xFF6366F1),
                tabs: measurements.map((m) => Tab(text: m)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: measurements.map((m) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getSpots(m),
                              isCurved: true,
                              barWidth: 3,
                              color: const Color(0xFF6366F1),
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
