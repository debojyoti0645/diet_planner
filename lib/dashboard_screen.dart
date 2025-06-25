import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, this.userName = "Alex"});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double? weight; // in kg
  double? height; // in cm
  int? age;
  String? gender;
  String? userName; // <-- Add this line
  String? userImagePath; // <-- Add this line

  final List<String> _nutritionTips = [
    '💡 Drink water before meals to aid digestion.',
    '🥗 Eat more whole foods and less processed food.',
    '🍎 Include fruits and veggies in every meal.',
    '🥤 Limit sugary drinks for better health.',
    '🍳 Start your day with a protein-rich breakfast.',
    '🧂 Reduce salt intake to maintain blood pressure.',
    '🥛 Choose low-fat dairy options.',
    '🍠 Prefer whole grains over refined grains.',
    '🍫 Enjoy treats in moderation.',
    '🍋 Add lemon to water for vitamin C boost.',
    '🥦 Try to eat a rainbow of vegetables.',
    '🍵 Green tea is a healthy beverage choice.',
  ];

  late String _selectedTip;

  // Example: You can persist these values using SharedPreferences or a database

  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final h = height! / 100;
      return weight! / (h * h);
    }
    return null;
  }

  void _showHealthDetailsDialog() {
    final nameController = TextEditingController(
      text: userName ?? widget.userName,
    ); // <-- Add this line
    final weightController = TextEditingController(
      text: weight?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: height?.toString() ?? '',
    );
    final ageController = TextEditingController(text: age?.toString() ?? '');
    String? selectedGender = gender;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Your Health Details'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController, // <-- Add this block
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    items:
                        ['Male', 'Female', 'Other']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                    onChanged: (val) => selectedGender = val,
                    decoration: const InputDecoration(labelText: 'Gender'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    userName = nameController.text; // <-- Add this line
                    weight = double.tryParse(weightController.text);
                    height = double.tryParse(heightController.text);
                    age = int.tryParse(ageController.text);
                    gender = selectedGender;
                  });
                  _saveHealthDetails();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveHealthDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null)
      prefs.setString('userName', userName!); // <-- Add this line
    if (weight != null) prefs.setDouble('weight', weight!);
    if (height != null) prefs.setDouble('height', height!);
    if (age != null) prefs.setInt('age', age!);
    if (gender != null) prefs.setString('gender', gender!);
  }

  Future<void> _loadHealthDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? widget.userName;
      weight = prefs.getDouble('weight');
      height = prefs.getDouble('height');
      age = prefs.getInt('age');
      gender = prefs.getString('gender');
      userImagePath = prefs.getString('userImagePath'); // <-- Add this line
    });
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Save the image directly without cropping
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'user_profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(
        picked.path,
      ).copy('${appDir.path}/$fileName');
      setState(() {
        userImagePath = savedImage.path;
      });
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userImagePath', userImagePath!);
    }
  }

  void _onProfileImageTap() {
    if (userImagePath == null) {
      _pickAndSaveImage();
    } else {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.visibility),
                    title: const Text('View Picture'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder:
                            (_) =>
                                Dialog(child: Image.file(File(userImagePath!))),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Change Picture'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSaveImage();
                    },
                  ),
                ],
              ),
            ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedTip = _nutritionTips[Random().nextInt(_nutritionTips.length)];
    _loadHealthDetails(); // <-- Load saved details on startup
  }

  @override
  Widget build(BuildContext context) {
    DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHealthDetailsCard(context),
              const SizedBox(height: 18),
              _buildNutritionTipCard(),
              const SizedBox(height: 18),
              _buildToolsSection(context),
              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthDetailsCard(BuildContext context) {
    final missing =
        weight == null || height == null || age == null || gender == null;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFD1FAE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(14),
        child:
            missing
                ? Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enter your health details to see your BMI and personalized stats.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: _showHealthDetailsDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'Fill Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _onProfileImageTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.08),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child:
                            userImagePath != null
                                ? ClipOval(
                                  child: Image.file(
                                    File(userImagePath!),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(
                                  Icons.person,
                                  color: Color(0xFF6366F1),
                                  size: 80,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? widget.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.monitor_weight,
                                color: Colors.indigo[400],
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Weight: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo[700],
                                ),
                              ),
                              Text('${weight?.toStringAsFixed(1)} kg'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.height,
                                color: Colors.green[400],
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Height: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text('${height?.toStringAsFixed(1)} cm'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.cake,
                                color: Colors.purple[400],
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Age: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                ),
                              ),
                              Text('$age'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.wc, color: Colors.pink[400], size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Gender: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink[700],
                                ),
                              ),
                              Text('$gender'),
                            ],
                          ),
                          if (bmi != null) ...[
                            const SizedBox(height: 10),
                            Divider(height: 1, color: Colors.indigo[100]),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: _bmiColor(bmi!),
                                  size: 22,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'BMI: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _bmiColor(bmi!),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${bmi!.toStringAsFixed(1)} (${_bmiCategory(bmi!)})',
                                  style: TextStyle(
                                    color: _bmiColor(bmi!),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Update Details",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF6366F1),
                                  ),
                                  onPressed: _showHealthDetailsDialog,
                                  tooltip: 'Update Details',
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
    );
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildNutritionTipCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFDE4), Color(0xFFFFF7AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.amber[100],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.lightbulb, color: Colors.amber, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                _selectedTip,
                style: const TextStyle(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7C5700),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    final tools = [
      {
        'icon': Icons.timer_rounded,
        'label': "Stopwatch",
        'color': Colors.deepPurpleAccent,
        'route': '/stopwatch',
      },
      {
        'icon': Icons.fitness_center_rounded,
        'label': "Body Matrix",
        'color': Colors.teal,
        'route': '/body_measurement',
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'label': "Calorie Burned",
        'color': Colors.orangeAccent,
        'route': '/calorie_burned_estimator',
      },
      {
        'icon': Icons.water_drop_rounded,
        'label': "Water Intake",
        'color': Colors.lightBlueAccent,
        'route': '/water_intake_calculator',
      },
      // Add more tools here
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
          child: Text(
            "Tools",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 10,
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 18,
              children:
                  tools.map((tool) {
                    return _modernToolShortcut(
                      context,
                      icon: tool['icon'] as IconData,
                      label: tool['label'] as String,
                      color: tool['color'] as Color,
                      onTap: () {
                        Navigator.pushNamed(context, tool['route'] as String);
                      },
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernToolShortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.13), Colors.white.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.18), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.95),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
