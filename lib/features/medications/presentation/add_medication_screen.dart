import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../data/medication_service.dart';
import '../../../core/widgets/shared_widgets.dart';

// -------------------- ADD MEDICATION SCREEN --------------------
class AddMedicationScreen extends StatefulWidget {
  final Medication? existingMedication; // For editing

  const AddMedicationScreen({super.key, this.existingMedication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationService = MedicationService();

  // Form controllers
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prescriberController = TextEditingController();
  final _notesController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  TimeOfDaySlot _selectedSlot = TimeOfDaySlot.morning;
  MedicationType _selectedType = MedicationType.tablet;
  List<String> _selectedDays = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  int _reminderMinutes = 15;

  @override
  void initState() {
    super.initState();
    _initializeDefaultDays();
    if (widget.existingMedication != null) {
      _populateExistingData();
    }
  }

  void _initializeDefaultDays() {
    _selectedDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
  }

  void _populateExistingData() {
    final med = widget.existingMedication!;
    _nameController.text = med.name;
    _doseController.text = med.dose;
    _descriptionController.text = med.description;
    _prescriberController.text = med.prescriber ?? '';
    _notesController.text = med.notes ?? '';
    _sideEffectsController.text = med.sideEffects ?? '';
    _instructionsController.text = med.instructions ?? '';

    _selectedSlot = med.slot;
    _selectedType = med.type;
    _selectedDays = List.from(med.schedule);
    _startDate = med.startDate;
    _endDate = med.endDate;
    _hasEndDate = med.endDate != null;
    _reminderMinutes = med.reminderMinutesBefore ?? 15;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _descriptionController.dispose();
    _prescriberController.dispose();
    _notesController.dispose();
    _sideEffectsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            GradientHeaderSliver(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            widget.existingMedication != null
                ? 'Edit Medication'
                : 'Add Medication',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildAdvancedSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Medication Name',
          hint: 'e.g., Aspirin',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter medication name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _doseController,
                label: 'Dose',
                hint: 'e.g., 100mg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dose';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildDropdownField<MedicationType>(
                label: 'Type',
                value: _selectedType,
                items: MedicationType.values,
                onChanged: (value) => setState(() => _selectedType = value!),
                itemBuilder: (type) => _getTypeDisplayName(type),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Brief description of the medication',
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Schedule'),
        const SizedBox(height: 16),
        _buildDropdownField<TimeOfDaySlot>(
          label: 'Time of Day',
          value: _selectedSlot,
          items: TimeOfDaySlot.values,
          onChanged: (value) => setState(() => _selectedSlot = value!),
          itemBuilder: (slot) => _getSlotDisplayName(slot),
        ),
        const SizedBox(height: 16),
        _buildDaysSelector(),
        const SizedBox(height: 16),
        _buildDateSection(),
        const SizedBox(height: 16),
        _buildReminderSection(),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Information'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _prescriberController,
          label: 'Prescriber (Optional)',
          hint: 'e.g., Dr. Smith',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _instructionsController,
          label: 'Instructions (Optional)',
          hint: 'e.g., Take with food',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _sideEffectsController,
          label: 'Side Effects (Optional)',
          hint: 'e.g., May cause drowsiness',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          hint: 'Additional notes',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2E2E2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6A6A6A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemBuilder(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6A6A6A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((day) {
            final isSelected = _selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  day.substring(0, 3),
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6A6A6A),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectStartDate(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _hasEndDate,
                        onChanged: (value) {
                          setState(() {
                            _hasEndDate = value!;
                            if (!_hasEndDate) _endDate = null;
                          });
                        },
                      ),
                      const Text('End Date'),
                    ],
                  ),
                  if (_hasEndDate)
                    _buildDateField(
                      label: 'End Date',
                      date:
                          _endDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      onTap: () => _selectEndDate(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6A6A6A)),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6A6A6A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Remind me'),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _reminderMinutes.toDouble(),
                min: 0,
                max: 120,
                divisions: 8,
                label: '$_reminderMinutes minutes before',
                onChanged: (value) {
                  setState(() => _reminderMinutes = value.round());
                },
              ),
            ),
            Text('$_reminderMinutes min before'),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveMedication,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.existingMedication != null
              ? 'Update Medication'
              : 'Add Medication',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day')),
        );
        return;
      }

      final medication = Medication(
        id:
            widget.existingMedication?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        dose: _doseController.text.trim(),
        description: _descriptionController.text.trim(),
        slot: _selectedSlot,
        schedule: _selectedDays,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        type: _selectedType,
        prescriber: _prescriberController.text.trim().isEmpty
            ? null
            : _prescriberController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        sideEffects: _sideEffectsController.text.trim().isEmpty
            ? null
            : _sideEffectsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        reminderMinutesBefore: _reminderMinutes,
      );

      if (widget.existingMedication != null) {
        _medicationService.updateMedication(medication);
      } else {
        _medicationService.addMedication(medication);
      }

      Navigator.pop(context, true); // Return true to indicate success
    }
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
}
