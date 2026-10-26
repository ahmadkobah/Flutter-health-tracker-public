import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/medication_service.dart';
import 'add_medication_screen.dart';
import 'medication_details_page.dart';
import '../../appointments/presentation/doctor_appointment_page.dart';
import '../../home/presentation/home_page.dart';
import '../../nutrition/presentation/nutrition_schedule_page.dart';
import '../../profile/presentation/profile_page.dart';

// -------------------- MEDICATION LIST --------------------
class MedicationListPage extends StatefulWidget {
  const MedicationListPage({super.key});

  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final _medicationService = MedicationService();
  final _searchController = TextEditingController();
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  String _searchQuery = '';
  TimeOfDaySlot? _filterSlot;

  @override
  void initState() {
    super.initState();
    _initializeMedications();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMedications() async {
    await _medicationService.initializeSampleData();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final medications = await _medicationService.getActiveMedications();
    setState(() {
      _medications = medications;
    });
    await _applyFilters();
  }

  Future<void> _onSearchChanged() async {
    setState(() {
      _searchQuery = _searchController.text;
    });
    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    List<Medication> filtered = _medications;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = await _medicationService.searchMedications(_searchQuery);
    }

    // Apply slot filter
    if (_filterSlot != null) {
      filtered = filtered.where((med) => med.slot == _filterSlot).toList();
    }

    setState(() {
      _filteredMedications = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            collapsedHeight: 0,
            toolbarHeight: 0,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FrostIcon(icon: Icons.medical_services_outlined),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Medications',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              '${_filteredMedications.length} medications',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSearchAndFilter(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: _buildMedicationList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        backgroundColor: const Color(0xFF6A5AE0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => NutritionSchedulePage(userId: 'your_user_id'),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DoctorAppointmentPage(userId: 'your_user_id'),
              ),
            );
          } else if (index == 4) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search medications...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6A6A6A)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6C63FF),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Morning', TimeOfDaySlot.morning),
                const SizedBox(width: 8),
                _buildFilterChip('Afternoon', TimeOfDaySlot.afternoon),
                const SizedBox(width: 8),
                _buildFilterChip('Evening', TimeOfDaySlot.evening),
                const SizedBox(width: 8),
                _buildFilterChip('Night', TimeOfDaySlot.night),
                const SizedBox(width: 8),
                _buildFilterChip('As Needed', TimeOfDaySlot.asNeeded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TimeOfDaySlot? slot) {
    final isSelected = _filterSlot == slot;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterSlot = isSelected ? null : slot;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6A6A6A),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
    if (_filteredMedications.isEmpty) {
      return _buildEmptyState();
    }

    // Group medications by time slot
    final groupedMedications = <TimeOfDaySlot, List<Medication>>{};
    for (final med in _filteredMedications) {
      groupedMedications.putIfAbsent(med.slot, () => []).add(med);
    }
    // We are already inside a sliver (SliverToBoxAdapter), so just build a Column.
    // Each section widget returns a Sliver previously; refactor section builder to return regular widgets for this context.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groupedMedications.entries.map(
          (entry) => _buildSlotSectionBody(entry.key, entry.value),
        ),
        const SizedBox(height: 96),
      ],
    );
  }

  // New body section for non-sliver context
  Widget _buildSlotSectionBody(
    TimeOfDaySlot slot,
    List<Medication> medications,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
              top: 8,
              left: 12,
              right: 12,
            ),
            child: Row(
              children: [
                Icon(
                  _getSlotIcon(slot),
                  size: 18,
                  color: const Color(0xFF6A5AE0),
                ),
                const SizedBox(width: 8),
                Text(
                  _getSlotDisplayName(slot),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  _countFor(slot, medications),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ...medications.map(
            (m) => _MedCard(
              med: m,
              onTap: () => _openDetails(m),
              onCheck: () => _toggleMedication(m),
              onEdit: () => _editMedication(m),
              onDelete: () => _deleteMedication(m),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No medications found'
                  : 'No medications added yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Add your first medication to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Medication'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _countFor(TimeOfDaySlot slot, List<Medication> medications) {
    final count = medications.length;
    return '$count medication${count == 1 ? '' : 's'}';
  }

  String _getSlotDisplayName(TimeOfDaySlot slot) {
    switch (slot) {
      case TimeOfDaySlot.morning:
        return 'Morning';
      case TimeOfDaySlot.afternoon:
        return 'Afternoon';
      case TimeOfDaySlot.evening:
        return 'Evening';
      case TimeOfDaySlot.night:
        return 'Night';
      case TimeOfDaySlot.asNeeded:
        return 'As Needed';
      case TimeOfDaySlot.beforeMeals:
        return 'Before Meals';
      case TimeOfDaySlot.afterMeals:
        return 'After Meals';
      case TimeOfDaySlot.withMeals:
        return 'With Meals';
    }
  }

  IconData _getSlotIcon(TimeOfDaySlot slot) {
    switch (slot) {
      case TimeOfDaySlot.morning:
        return Icons.wb_sunny_outlined;
      case TimeOfDaySlot.afternoon:
        return Icons.wb_cloudy_outlined;
      case TimeOfDaySlot.evening:
        return Icons.nights_stay_outlined;
      case TimeOfDaySlot.night:
        return Icons.bedtime_outlined;
      case TimeOfDaySlot.asNeeded:
        return Icons.medical_services_outlined;
      case TimeOfDaySlot.beforeMeals:
      case TimeOfDaySlot.afterMeals:
      case TimeOfDaySlot.withMeals:
        return Icons.restaurant_outlined;
    }
  }

  void _toggleMedication(Medication medication) {
    if (medication.taken) {
      _medicationService.markMedicationNotTaken(medication.id);
    } else {
      _medicationService.markMedicationTaken(medication.id);
    }
    _loadMedications();
  }

  void _addMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
    if (result == true) {
      _loadMedications();
    }
  }

  void _editMedication(Medication medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(existingMedication: medication),
      ),
    );
    if (result == true) {
      _loadMedications();
    }
  }

  void _deleteMedication(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _medicationService.deleteMedication(medication.id);
              _loadMedications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${medication.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openDetails(Medication m) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MedicationDetailsPage(med: m)));
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MedCard({
    required this.med,
    required this.onTap,
    required this.onCheck,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildMedicationIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF303035),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C6BFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              med.dose,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5C6BFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeDisplayName(med.type),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9BA1AB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        med.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9BA1AB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (med.instructions != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          med.instructions!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9BA1AB),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: onCheck,
                      child: CheckBox(ticked: med.taken),
                    ),
                    if (onEdit != null || onDelete != null) ...[
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF9BA1AB),
                          size: 18,
                        ),
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit?.call();
                              break;
                            case 'delete':
                              onDelete?.call();
                              break;
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationIcon() {
    IconData iconData;
    Color iconColor;

    switch (med.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        iconData = Icons.medication;
        iconColor = const Color(0xFF6A5AE0);
        break;
      case MedicationType.liquid:
        iconData = Icons.local_drink;
        iconColor = const Color(0xFF2EAC5F);
        break;
      case MedicationType.injection:
        iconData = Icons.medical_services;
        iconColor = const Color(0xFFFF6B6B);
        break;
      case MedicationType.inhaler:
        iconData = Icons.air;
        iconColor = const Color(0xFF4ECDC4);
        break;
      case MedicationType.cream:
        iconData = Icons.healing;
        iconColor = const Color(0xFFFFE66D);
        break;
      case MedicationType.drops:
        iconData = Icons.water_drop;
        iconColor = const Color(0xFF4DABF7);
        break;
      default:
        iconData = Icons.medication_outlined;
        iconColor = const Color(0xFF9BA1AB);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _getTypeDisplayName(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.liquid:
        return 'Liquid';
      case MedicationType.injection:
        return 'Injection';
      case MedicationType.cream:
        return 'Cream';
      case MedicationType.drops:
        return 'Drops';
      case MedicationType.inhaler:
        return 'Inhaler';
      case MedicationType.patch:
        return 'Patch';
      case MedicationType.spray:
        return 'Spray';
      case MedicationType.other:
        return 'Other';
    }
  }
}
