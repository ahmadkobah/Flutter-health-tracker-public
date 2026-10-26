import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'add_medication_screen.dart';
import '../data/medication_service.dart';

class MedicationDetailsPage extends StatefulWidget {
  final Medication med;
  const MedicationDetailsPage({super.key, required this.med});

  @override
  State<MedicationDetailsPage> createState() => _MedicationDetailsPageState();
}

class _MedicationDetailsPageState extends State<MedicationDetailsPage> {
  final _medicationService = MedicationService();
  late Medication medication;

  @override
  void initState() {
    super.initState();
    medication = widget.med;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            GradientHeaderSliver(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Medication Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.edit_outlined,
                      onTap: _editMedication,
                    ),
                  ],
                ),
              ),
            ),
            // Info Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MedAvatar(),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                medication.dose,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5C6BFF),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusChip(
                          'Pending',
                          const Color(0xFFFFF2E3),
                          const Color(0xFFEEA458),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _DetailsSection(
              title: 'Details',
              child: _DetailsGrid(med: medication),
            ),
            _DetailsSection(
              title: 'Schedule',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: medication.schedule
                    .map((d) => _DayPill(_safeDayAbbrev(d)))
                    .toList(),
              ),
            ),
            if (medication.notes != null && medication.notes!.isNotEmpty)
              _DetailsSection(
                title: 'Notes',
                child: _NotesBox(text: medication.notes!),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _safeDayAbbrev(String d) => d.length <= 3 ? d : d.substring(0, 3);

  Widget _buildStatusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  void _editMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(existingMedication: medication),
      ),
    );
    if (result == true) {
      final updatedMed = await _medicationService.getMedicationById(
        medication.id,
      );
      if (updatedMed != null) {
        setState(() => medication = updatedMed);
      }
    }
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: .8,
          ),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final Medication med;
  const _DetailsGrid({required this.med});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _KVRow(label: 'Type', value: _getTypeDisplayName(med.type)),
        const SizedBox(height: 8),
        _KVRow(label: 'Frequency', value: _getFrequencyText()),
        const SizedBox(height: 8),
        _KVRow(label: 'Time', value: _getSlotDisplayName(med.slot)),
        const SizedBox(height: 8),
        _KVRow(label: 'Start Date', value: _formatDate(med.startDate)),
        if (med.endDate != null) ...[
          const SizedBox(height: 8),
          _KVRow(label: 'End Date', value: _formatDate(med.endDate!)),
        ],
        if (med.prescriber != null) ...[
          const SizedBox(height: 8),
          _KVRow(label: 'Prescriber', value: med.prescriber!),
        ],
        if (med.reminderMinutesBefore != null) ...[
          const SizedBox(height: 8),
          _KVRow(
            label: 'Reminder',
            value: '${med.reminderMinutesBefore} min before',
          ),
        ],
      ],
    );
  }

  String _getFrequencyText() {
    if (med.slot == TimeOfDaySlot.asNeeded) {
      return 'As needed';
    }
    if (med.schedule.length == 7) {
      return 'Daily';
    }
    if (med.schedule.length == 1) {
      return 'Once a week';
    }
    return '${med.schedule.length} times per week';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(color: Color(0xFF6A6A6A))),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  final String day;
  const _DayPill(this.day);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        day,
        style: const TextStyle(
          color: Color(0xFF6C63FF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String text;
  const _NotesBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7F3)),
      ),
      child: Text(text),
    );
  }
}
