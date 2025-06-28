import 'dart:io'; // Required for File operations
import 'package:checkmate/auth/auth_service.dart';
import 'package:checkmate/home/home_page.dart';
import 'package:checkmate/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // --- Controllers and State Variables ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _task1Controller = TextEditingController();
  final TextEditingController _task2Controller = TextEditingController();
  final TextEditingController _task3Controller = TextEditingController();
  final TextEditingController _task4Controller = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _avatarUrl;
  
  // --- Feature: Dropdown selection state ---
  String? _selectedSex;
  String? _selectedGoal;
  String? _selectedAcademicQualification;
  DateTime? _selectedDeadline;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _deadlineController.dispose();
    _task1Controller.dispose();
    _task2Controller.dispose();
    _task3Controller.dispose();
    _task4Controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('profiles')
          .select('*, avatar_url, description')
          .eq('id', userId)
          .single();

      _nameController.text = response['name'] ?? '';
      _ageController.text = response['age']?.toString() ?? '';
      _descriptionController.text = response['description'] ?? '';
      setState(() {
        _selectedSex = response['sex'];
        _selectedGoal = response['goal'];
        _selectedAcademicQualification = response['academic_qualification'];
        _avatarUrl = response['avatar_url'];
      });

      if (response['deadline'] != null) {
        _selectedDeadline = DateTime.parse(response['deadline']);
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(_selectedDeadline!);
      }

      _task1Controller.text = response['task_1'] ?? '';
      _task2Controller.text = response['task_2'] ?? '';
      _task3Controller.text = response['task_3'] ?? '';
      _task4Controller.text = response['task_4'] ?? '';
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST116' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (imageFile == null) return;
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final file = File(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from('avatars').upload(filePath, file);
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      setState(() { _avatarUrl = imageUrl; });
      await _supabase.from('profiles').upsert({'id': userId, 'avatar_url': imageUrl});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading avatar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _upsertProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final profileData = {
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'sex': _selectedSex, // Uses dropdown value
        'description': _descriptionController.text.trim(),
        'avatar_url': _avatarUrl,
        'goal': _selectedGoal,
        'academic_qualification': _selectedAcademicQualification,
        'deadline': _selectedDeadline?.toIso8601String().split('T').first,
        'task_1': _task1Controller.text.trim(),
        'task_2': _task2Controller.text.trim(),
        'task_3': _task3Controller.text.trim(),
        'task_4': _task4Controller.text.trim(),
      };
      await _supabase.from('profiles').upsert(profileData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _selectDeadline(BuildContext context) async {
     final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void logout() async {
    await authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Theme: Consistent color and input decoration ---
    const Color primaryColor = Color(0xFFFDFCF8);
    const Color secondaryColor = Color(0xFFF0EAE3);
    const Color textColor = Color(0xFF333333);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: secondaryColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      labelStyle: const TextStyle(color: textColor),
    );

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryColor,
        body: Center(child: CircularProgressIndicator(color: textColor)),
      );
    }

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: secondaryColor,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickAndUploadAvatar,
                  child: const Text('Change Photo', style: TextStyle(color: textColor)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(labelText: "Name*"),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: inputDecoration.copyWith(labelText: "Short Description", hintText: "Tell us a bit about yourself..."),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: inputDecoration.copyWith(labelText: "Age*"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Age is required';
                  if (int.tryParse(value.trim()) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- Feature: User-friendly dropdown for 'Sex' ---
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: inputDecoration.copyWith(labelText: "Sex*"),
                items: ['male', 'female'].map((val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _selectedSex = val),
                validator: (val) => val == null ? 'Please select your sex' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: inputDecoration.copyWith(labelText: "Main Goal*"),
                items: ['JEE', 'NEET', 'Boards', 'Coding'].map((val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _selectedGoal = val),
                validator: (val) => val == null ? 'Please select a goal' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAcademicQualification,
                decoration: inputDecoration.copyWith(labelText: "Academic Qualification*"),
                items: ['10th', '11th', '12th', 'B.tech 1st year', 'B.tech 2nd year', 'B.tech 3rd year'].map((val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _selectedAcademicQualification = val),
                validator: (val) => val == null ? 'Please select a qualification' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deadlineController,
                decoration: inputDecoration.copyWith(labelText: "Goal Deadline*", suffixIcon: Icon(Icons.calendar_today, color: textColor.withOpacity(0.6))),
                readOnly: true,
                onTap: () => _selectDeadline(context),
                validator: (val) => (val == null || val.isEmpty) ? 'Deadline is required' : null,
              ),
              const SizedBox(height: 24),
              const Text("Your Four Daily Tasks:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),
              TextFormField(controller: _task1Controller, decoration: inputDecoration.copyWith(labelText: "Daily Task 1*"), validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _task2Controller, decoration: inputDecoration.copyWith(labelText: "Daily Task 2*"), validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _task3Controller, decoration: inputDecoration.copyWith(labelText: "Daily Task 3*"), validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _task4Controller, decoration: inputDecoration.copyWith(labelText: "Daily Task 4*"), validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _upsertProfile,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3))
                    : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}