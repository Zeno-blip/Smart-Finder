// register.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_finder/LANDLORD/LOGIN.dart';
import 'package:smart_finder/LANDLORD/VERIFICATION.dart';

class RegisterL extends StatefulWidget {
  const RegisterL({super.key});

  @override
  State<RegisterL> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterL> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();
  final _apartmentNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = 'Male';
  bool _loading = false;

  PlatformFile? _barangayClearance;
  PlatformFile? _businessPermit;
  PlatformFile? _validId1;
  PlatformFile? _validId2;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _apartmentNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _sendOtp({
    required String email,
    required String userId,
    required String fullName,
  }) async {
    final res = await supabase.functions.invoke(
      'send_otp',
      body: {'email': email, 'user_id': userId, 'full_name': fullName},
    );
    if (res.status >= 400) {
      throw Exception("Failed to send code: ${res.data}");
    }
  }

  // ---------- NEW: ensure user has landlord role for RLS ----------
  Future<void> _ensureLandlordRole(String userId) async {
    try {
      // If you have a unique constraint on (user_id, role), upsert avoids duplicates
      await supabase.from('user_roles').upsert({
        'user_id': userId,
        'role': 'landlord',
      }, onConflict: 'user_id,role');
    } catch (_) {
      // If your schema doesn’t support onConflict, fall back to insert and ignore dup errors
      try {
        await supabase.from('user_roles').insert({
          'user_id': userId,
          'role': 'landlord',
        });
      } catch (e) {
        // ignore if it already exists
      }
    }
  }

  // ------------------ Document picking & upload ------------------

  Future<void> _pickDoc(void Function(PlatformFile?) assign) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'heic', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null) {
        _msg('Failed to read file bytes. Try another file.');
        return;
      }
      assign(file);
      setState(() {});
    }
  }

  Future<void> _uploadOneDoc({
    required String userId,
    required PlatformFile file,
    required String docType,
  }) async {
    final Uint8List bytes = file.bytes!;
    String clean(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');

    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final original = file.name;
    final path = '$userId/${ts}_${clean(docType)}_${clean(original)}';

    await supabase.storage
        .from('landlord-docs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/octet-stream',
            upsert: true,
          ),
        );

    await supabase.from('landlord_documents').insert({
      'user_id': userId,
      'doc_type': docType,
      'storage_path': path,
      'original_filename': original,
    });
  }

  Future<void> _uploadAllDocs(String userId) async {
    if (_barangayClearance != null) {
      await _uploadOneDoc(
        userId: userId,
        file: _barangayClearance!,
        docType: 'barangay_clearance',
      );
    }
    if (_businessPermit != null) {
      await _uploadOneDoc(
        userId: userId,
        file: _businessPermit!,
        docType: 'business_permit',
      );
    }
    if (_validId1 != null) {
      await _uploadOneDoc(
        userId: userId,
        file: _validId1!,
        docType: 'valid_id',
      );
    }
    if (_validId2 != null) {
      await _uploadOneDoc(
        userId: userId,
        file: _validId2!,
        docType: 'valid_id_2',
      );
    }
  }

  // ------------------ Registration ------------------

  Future<void> _registerLandlord() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthday = _birthdayController.text.trim();
    final address = _addressController.text.trim();
    final aptName = _apartmentNameController.text.trim();
    final phone = _contactNumberController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _msg('All required fields must be filled.');
      return;
    }
    if (!email.contains('@')) {
      _msg('Please enter a valid email.');
      return;
    }
    if (password != confirmPassword) {
      _msg('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      final existingUser = await supabase
          .from('users')
          .select('id, email, role')
          .eq('email', email)
          .maybeSingle();

      String userId;

      if (existingUser == null) {
        // 1) Auth sign-up
        final signUpRes = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': '$firstName $lastName', 'role': 'landlord'},
        );
        final authUser = signUpRes.user;
        if (authUser == null) {
          throw const AuthException(
            'Sign-up created but no user returned. Check email confirmations in project settings.',
          );
        }
        userId = authUser.id;

        // 2) users row (unverified)
        final hashed = sha256.convert(utf8.encode(password)).toString();
        await supabase.from('users').upsert({
          'id': userId,
          'full_name': '$firstName $lastName',
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone.isEmpty ? null : phone,
          'password': hashed,
          'role': 'landlord',
          'is_verified': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id');

        // 2.5) **Make sure RLS sees them as landlord**
        await _ensureLandlordRole(userId);

        // 3) landlord_profile (RLS now allows this)
        await supabase.from('landlord_profile').upsert({
          'user_id': userId,
          'first_name': firstName,
          'last_name': lastName,
          'birthday': birthday.isEmpty ? null : birthday,
          'gender': _selectedGender,
          'address': address.isEmpty ? null : address,
          'apartment_name': aptName.isEmpty ? null : aptName,
          'contact_number': phone.isEmpty ? null : phone,
        }, onConflict: 'user_id');
      } else {
        // Existing email – sign in to prove ownership
        final signInRes = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final authUser = signInRes.user;
        if (authUser == null) {
          _msg(
            'This email already exists. Enter the same password used for this email.',
          );
          return;
        }
        userId = authUser.id;

        // Keep users row in sync
        final hashed = sha256.convert(utf8.encode(password)).toString();
        await supabase.from('users').upsert({
          'id': userId,
          'full_name': '$firstName $lastName',
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone.isEmpty ? null : phone,
          'password': hashed,
          'role': existingUser['role'] ?? 'landlord',
          'is_verified': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id');

        // 2.5) **Ensure landlord role for RLS**
        await _ensureLandlordRole(userId);

        // landlord_profile
        await supabase.from('landlord_profile').upsert({
          'user_id': userId,
          'first_name': firstName,
          'last_name': lastName,
          'birthday': birthday.isEmpty ? null : birthday,
          'gender': _selectedGender,
          'address': address.isEmpty ? null : address,
          'apartment_name': aptName.isEmpty ? null : aptName,
          'contact_number': phone.isEmpty ? null : phone,
        }, onConflict: 'user_id');

        // sign out; they’ll verify via OTP next
        await supabase.auth.signOut();
      }

      // 4) Optional documents
      await _uploadAllDocs(userId);

      // 5) Send OTP
      await _sendOtp(
        email: email,
        userId: userId,
        fullName: '$firstName $lastName',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Verification(email: email, userId: userId),
        ),
      );
    } on AuthException catch (e) {
      _msg('Auth error: ${e.message}');
    } on PostgrestException catch (e) {
      _msg('Database error: ${e.message}');
    } catch (e) {
      _msg('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00324E), Color(0xFF005B96)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/images/logo1.png', height: 230),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create your account.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  _firstNameController,
                  'First Name',
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _lastNameController,
                  'Last Name',
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            _birthdayController,
                            'Birthday',
                            Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownField(
                        'Gender',
                        _selectedGender,
                        Icons.male,
                        (value) =>
                            setState(() => _selectedGender = value ?? 'Male'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildTextField(
                  _addressController,
                  'Address',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _apartmentNameController,
                  'Apartments Name',
                  Icons.apartment,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _contactNumberController,
                  'Contact Number',
                  Icons.phone_outlined,
                  inputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _emailController,
                  'Email',
                  Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  'Password',
                  Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _confirmPasswordController,
                  'Confirm Password',
                  Icons.lock_outline,
                  obscureText: true,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _uploadButton(
                        label: 'Barangay Clearance',
                        picked: _barangayClearance,
                        onPick: () => _pickDoc((f) => _barangayClearance = f),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _uploadButton(
                        label: 'Business Permit',
                        picked: _businessPermit,
                        onPick: () => _pickDoc((f) => _businessPermit = f),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _uploadButton(
                        label: 'Valid ID',
                        picked: _validId1,
                        onPick: () => _pickDoc((f) => _validId1 = f),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _uploadButton(
                        label: 'Valid ID 2',
                        picked: _validId2,
                        onPick: () => _pickDoc((f) => _validId2 = f),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _registerLandlord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'REGISTER',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadButton({
    required String label,
    required VoidCallback onPick,
    PlatformFile? picked,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPick,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.upload_file),
        label: Text(
          picked == null ? label : '${label} • ${picked.name}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[300],
          prefixIcon: Icon(icon),
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String hint,
    String currentValue,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      height: 50,
      child: DropdownButtonFormField<String>(
        value: currentValue,
        isDense: true,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[300],
          prefixIcon: Icon(icon),
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
      ),
    );
  }
}
