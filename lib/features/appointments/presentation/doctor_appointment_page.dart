import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/appointment_service.dart';
import '../../home/presentation/home_page.dart';
import '../../medications/presentation/medication_list_page.dart';
import '../../nutrition/presentation/nutrition_schedule_page.dart';
import '../../profile/presentation/profile_page.dart';

class DoctorAppointmentPage extends StatefulWidget {
  final String userId;
  const DoctorAppointmentPage({super.key, required this.userId});

  @override
  State<DoctorAppointmentPage> createState() => _DoctorAppointmentPageState();
}

class _DoctorAppointmentPageState extends State<DoctorAppointmentPage> {
  final _appointmentService = AppointmentService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _doctorNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  // Form state
  List<DoctorAppointment> _appointments = [];
  List<DoctorAppointment> _filteredAppointments = [];
  bool _isLoading = false;
  bool _isFormExpanded = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _searchQuery = '';
  Stream<List<DoctorAppointment>>? _appointmentsStream;
  StreamSubscription<List<DoctorAppointment>>? _appointmentsSub;

  // App color constants
  static const Color kPrimary = Color(0xFF6A5AE0); // Purple (matches medication page)
  static const Color kTextPrimary = Color(0xFF1A1A1A);
  static const Color kTextTertiary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _validateUserId();
    _searchController.addListener(_onSearchChanged);
    // Subscribe to realtime updates
    _appointmentsStream = _appointmentService.getAppointmentsStream();
    _appointmentsSub = _appointmentsStream?.listen((appointments) {
      if (mounted) {
        setState(() {
          _appointments = appointments;
        });
        _applyFilters();
      }
    });
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialtyController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _appointmentsSub?.cancel();
    super.dispose();
  }

  void _validateUserId() {
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
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      await _appointmentService.initializeSampleData();
      // initial load is handled by stream subscription; keep this for sample data init
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<DoctorAppointment> filtered = _appointments;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((appointment) {
        return appointment.doctorName.toLowerCase().contains(lowercaseQuery) ||
            appointment.specialty.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    setState(() {
      _filteredAppointments = filtered;
    });
  }

  void _clearForm() {
    _doctorNameController.clear();
    _specialtyController.clear();
    _locationController.clear();
    _addressController.clear();
    _phoneController.clear();
    _notesController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _addAppointment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appointment = DoctorAppointment(
        id: '',
        doctorName: _doctorNameController.text.trim(),
        specialty: _specialtyController.text.trim(),
        appointmentDate: _selectedDate!,
        appointmentTime: _selectedTime!,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: AppointmentStatus.scheduled,
        reminderMinutesBefore: 30,
        createdAt: DateTime.now(),
      );

      await _appointmentService.createAppointment(appointment);
      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _deleteAppointment(DoctorAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel the appointment with ${appointment.doctorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _appointmentService.deleteAppointment(appointment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling appointment: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FrostIcon(icon: Icons.medical_services_rounded),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Doctor Appointments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Schedule and manage appointments',
                              style: TextStyle(color: Colors.white70, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
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
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Add appointment form
                        _buildAddAppointmentForm(),
                        const SizedBox(height: 24),
                        // Appointments list
                        Text(
                          'Upcoming Appointments (${_filteredAppointments.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._filteredAppointments.map(
                          (appointment) => _buildAppointmentCard(appointment),
                        ),
                        if (_filteredAppointments.isEmpty && !_isLoading)
                          _buildEmptyState(),
                      ],
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
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MedicationListPage()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => NutritionSchedulePage(userId: widget.userId),
              ),
            );
          } else if (index == 3) {
            // Already on Appointments page
          } else if (index == 4) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildAddAppointmentForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFormExpanded = !_isFormExpanded;
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.add_box, color: kPrimary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Schedule Appointment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isFormExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.expand_more,
                      color: kPrimary,
                      size: 24,
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
                  const SizedBox(height: 16),
                  // Doctor name and specialty
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _doctorNameController,
                          decoration: InputDecoration(
                            labelText: 'Doctor Name *',
                            labelStyle:
                                const TextStyle(color: Color(0xFF6B7280)),
                            prefixIcon:
                                const Icon(Icons.person, color: kPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: kPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _specialtyController,
                          decoration: InputDecoration(
                            labelText: 'Specialty *',
                            labelStyle:
                                const TextStyle(color: Color(0xFF6B7280)),
                            prefixIcon: const Icon(
                              Icons.local_hospital,
                              color: kPrimary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: kPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date and time
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF8F9FA),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: kPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null
                                      ? 'Select Date *'
                                      : DateFormat('MMM dd, yyyy')
                                          .format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF303035),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF8F9FA),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: kPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime == null
                                      ? 'Select Time *'
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    color: _selectedTime == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF303035),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Location and address
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location/Clinic',
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      prefixIcon:
                          const Icon(Icons.location_on, color: kPrimary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: kPrimary, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      prefixIcon: const Icon(Icons.map, color: kPrimary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: kPrimary, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Phone and notes
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            labelStyle:
                                const TextStyle(color: Color(0xFF6B7280)),
                            prefixIcon:
                                const Icon(Icons.phone, color: kPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: kPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            labelStyle:
                                const TextStyle(color: Color(0xFF6B7280)),
                            prefixIcon: const Icon(Icons.note, color: kPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: kPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _addAppointment,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Schedule Appointment',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _isFormExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(DoctorAppointment appointment) {
    final statusColor = _getStatusColor(appointment.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: kPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName,
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
                                color: kPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appointment.specialty,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kPrimary,
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
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appointment.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: const Color(0xFF9BA1AB)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy')
                        .format(appointment.appointmentDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9BA1AB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 14, color: const Color(0xFF9BA1AB)),
                  const SizedBox(width: 6),
                  Text(
                    appointment.appointmentTime.format(context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9BA1AB),
                    ),
                  ),
                ],
              ),
              if (appointment.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: const Color(0xFF9BA1AB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9BA1AB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (appointment.notes != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.note, size: 14, color: const Color(0xFF9BA1AB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9BA1AB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (appointment.phoneNumber != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Call ${appointment.phoneNumber}'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone, size: 14),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(color: kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (appointment.phoneNumber != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteAppointment(appointment),
                      icon: const Icon(Icons.delete, size: 14),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by doctor or specialty...',
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF6A6A6A),
          ),
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
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: kPrimary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: kTextTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule your first appointment using the form above',
            style: TextStyle(
              fontSize: 14,
              color: kTextTertiary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.rescheduled:
        return Colors.orange;
      case AppointmentStatus.noShow:
        return Colors.red.shade800;
    }
  }
}
