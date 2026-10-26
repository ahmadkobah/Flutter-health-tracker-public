import '../../profile/presentation/profile_page.dart';

import '../../home/presentation/home_page.dart';
import '../../medications/presentation/medication_list_page.dart';
import '../../appointments/presentation/doctor_appointment_page.dart';
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/nutrition_schedule_service.dart';

class NutritionSchedulePage extends StatefulWidget {
  final String userId;
  const NutritionSchedulePage({super.key, required this.userId});

  @override
  State<NutritionSchedulePage> createState() => _NutritionSchedulePageState();
}

class _NutritionSchedulePageState extends State<NutritionSchedulePage> {
  final _nutritionService = NutritionScheduleService();
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  final Map<String, IconData> _mealIcons = {
    'Breakfast': Icons.free_breakfast,
    'Lunch': Icons.lunch_dining,
    'Dinner': Icons.nightlife,
    'Snacks': Icons.fastfood,
  };

  // App color constants (from design system)
  static const Color kPrimary = Color(0xFF6A5AE0); // Purple (matches medication page)
  static const Color kSecondary = Color(0xFF06B6D4); // Cyan-500
  static const Color kCard = Colors.white;
  static const Color kTextPrimary = Color(0xFF1A1A1A);
  static const Color kTextSecondary = Color(0xFF374151);
  static const Color kTextTertiary = Color(0xFF6B7280);
  Map<String, List<Map<String, dynamic>>> _meals = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snacks': [],
  };
  bool _isLoading = false;
  bool _isDishFormExpanded = false;

  String _currentMeal = 'Breakfast';
  String _dishName = '';
  String _dishWeight = '';

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      // Use secure service instead of direct Firebase calls
      await _nutritionService.setAllMeals(_meals);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition schedule saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving schedule: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      Map<String, List<Map<String, dynamic>>> loadedMeals = {
        for (var meal in _mealTypes) meal: [],
      };

      // Use secure service to load meals
      for (final meal in _mealTypes) {
        loadedMeals[meal] = await _nutritionService.getMeals(meal);
      }

      if (mounted) {
        setState(() {
          _meals = loadedMeals;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    // Validate that we have a userId
    if (widget.userId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No user ID provided. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      });
      return;
    }
    _loadSchedule();
  }

  void _addDish() {
    if (_dishName.isNotEmpty && _dishWeight.isNotEmpty) {
      setState(() {
        _meals[_currentMeal]!.add({'name': _dishName, 'weight': _dishWeight});
        _dishName = '';
        _dishWeight = '';
      });
      _saveSchedule();
    }
  }

  void _removeDish(String meal, int index) {
    setState(() {
      _meals[meal]!.removeAt(index);
    });
    _saveSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6A5AE0), Color(0xFF8364E8)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FrostIcon(icon: Icons.restaurant_menu_rounded),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nutrition Schedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Plan your meals for the week',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: kCard,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with expand/collapse button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDishFormExpanded = !_isDishFormExpanded;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add_box,
                                        color: kPrimary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Add a Dish',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: kTextPrimary,
                                          ),
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: _isDishFormExpanded ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(
                                          Icons.expand_more,
                                          color: kPrimary,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Animated form content
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: _currentMeal,
                                        items: _mealTypes
                                            .map(
                                              (meal) => DropdownMenuItem(
                                                value: meal,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _mealIcons[meal],
                                                      color: kPrimary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      meal,
                                                      style: TextStyle(
                                                        color: kTextPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _currentMeal = val);
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Meal',
                                          labelStyle: const TextStyle(
                                            color: kTextTertiary,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: kPrimary),
                                          ),
                                        ),
                                        dropdownColor: kCard,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Dish Name',
                                          labelStyle: const TextStyle(
                                            color: kTextTertiary,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.restaurant_menu,
                                            color: kPrimary,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: kPrimary),
                                          ),
                                        ),
                                        style: const TextStyle(color: kTextPrimary),
                                        onChanged: (val) => _dishName = val,
                                        initialValue: _dishName,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Weight (g)',
                                          labelStyle: const TextStyle(
                                            color: kTextTertiary,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.scale,
                                            color: kPrimary,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: kPrimary),
                                          ),
                                        ),
                                        style: const TextStyle(color: kTextPrimary),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => _dishWeight = val,
                                        initialValue: _dishWeight,
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          onPressed: _addDish,
                                          icon: const Icon(Icons.add),
                                          label: const Text(
                                            'Add Dish',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  crossFadeState: _isDishFormExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._mealTypes.map((meal) => _buildMealCard(meal)),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => MedicationListPage()),
            );
          } else if (index == 2) {
            // Already on Nutrition page
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DoctorAppointmentPage(userId: widget.userId),
              ),
            );
          } else if (index == 4) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => ProfilePage()));
          }
        },
      ),
    );
  }

  Widget _buildMealCard(String meal) {
    final dishes = _meals[meal]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 18),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: kCard,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_mealIcons[meal], color: kPrimary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    meal,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (dishes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No dishes added yet.',
                    style: TextStyle(color: kTextTertiary),
                  ),
                ),
              ...dishes.asMap().entries.map((entry) {
                final idx = entry.key;
                final dish = entry.value;
                return Dismissible(
                  key: ValueKey('${meal}_$idx'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeDish(meal, idx),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: const Color(0xFFEF4444), // Error/500
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: kPrimary.withValues(alpha: 0.08),
                      child: const Icon(Icons.restaurant, color: kPrimary),
                    ),
                    title: Text(
                      '${dish['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: kTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Weight: ${dish['weight']} g',
                      style: const TextStyle(color: kTextSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                      onPressed: () => _removeDish(meal, idx),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
