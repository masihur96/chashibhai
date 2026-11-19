import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/localization.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _districtController;
  late TextEditingController _avatarUrlController;

  Uint8List? _localAvatarBytes;
  String? _localAvatarPath;

  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  static const List<String> _commonDistricts = [
    'Bogura',
    'Dinajpur',
    'Rajshahi',
    'Rangpur',
    'Jashore',
    'Mymensingh',
    'Cumilla',
    'Sylhet',
    'Dhaka',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(
      text: user?.name.isNotEmpty == true && user!.name != 'User' ? user.name : '',
    );
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _districtController = TextEditingController(
      text: user?.district?.isNotEmpty == true ? user!.district! : 'Bogura',
    );
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');

    _avatarUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  // ─── Image Picking & Upload ──────────────────────────────────────────────────

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      final uploadItem = await UploadFileItem.fromXFile(file);

      setState(() {
        _localAvatarBytes = uploadItem.bytes;
        _localAvatarPath = file.path;
        _isUploadingAvatar = true;
      });

      _showSnackBar(
        message: 'Uploading photo to server...',
        icon: Icons.cloud_upload_outlined,
        color: AppColors.primary,
      );

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        token = await StorageService().getAccessToken();
      }

      // Execute POST /api/v1/upload matching the user's curl specification:
      // curl -X 'POST' 'http://localhost:3000/api/v1/upload' -H 'accept: application/json' ... -F 'files=@...'
      final urls = await UploadService().uploadFiles(
        items: [uploadItem],
        token: token,
      );

      if (!mounted) return;

      if (urls.isNotEmpty) {
        final uploadedUrl = urls.first;
        setState(() {
          _avatarUrlController.text = uploadedUrl;
          _isUploadingAvatar = false;
        });

        _showSnackBar(
          message: 'Avatar uploaded successfully!',
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
        );
      } else {
        setState(() => _isUploadingAvatar = false);
        _showSnackBar(
          message: 'Upload succeeded but no image URL was returned.',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange.shade800,
        );
      }
    } on PlatformException catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) {
        _showSnackBar(
          message: 'Could not access camera/gallery: ${e.message}',
          icon: Icons.error_outline,
          color: Colors.red.shade700,
        );
      }
    } catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) {
        final err = e.toString().replaceFirst('Exception: ', '');
        _showSnackBar(
          message: 'Failed to upload photo: $err',
          icon: Icons.error_outline,
          color: Colors.red.shade700,
        );
      }
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Profile Photo',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Select an option to update your photo',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF9FAFB),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: Text('Take Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Capture with camera & upload directly', style: GoogleFonts.outfit(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF9FAFB),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Select an image from device gallery', style: GoogleFonts.outfit(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF9FAFB),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.link_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  title: Text('Enter Image URL', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Paste a web image URL or preset', style: GoogleFonts.outfit(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlInputDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUrlInputDialog() {
    final tempController = TextEditingController(text: _avatarUrlController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Avatar URL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tempController,
              decoration: InputDecoration(
                labelText: 'Image Web URL',
                hintText: 'https://cdn.example.com/avatar.jpg',
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sample Presets:',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  backgroundColor: const Color(0xFFF4F6F9),
                  label: Text('Preset 1 (Farmer)', style: GoogleFonts.outfit(fontSize: 12)),
                  onPressed: () {
                    tempController.text =
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400';
                  },
                ),
                ActionChip(
                  backgroundColor: const Color(0xFFF4F6F9),
                  label: Text('Preset 2 (Professional)', style: GoogleFonts.outfit(fontSize: 12)),
                  onPressed: () {
                    tempController.text =
                        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400';
                  },
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              final newUrl = tempController.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _avatarUrlController.text = newUrl;
                  _localAvatarBytes = null;
                  _localAvatarPath = null;
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Save Profile (PATCH /api/v1/users/profile) ──────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isUploadingAvatar) {
      _showSnackBar(
        message: 'Please wait for photo upload to finish...',
        icon: Icons.hourglass_top_rounded,
        color: Colors.orange.shade800,
      );
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();

    // Executes PATCH /api/v1/users/profile matching the user's curl specification:
    // curl -X 'PATCH' 'http://localhost:3000/api/v1/users/profile' -H 'accept: */*' ...
    // -d '{"name": "...", "avatarUrl": "...", "avatar_url": "...", "avatar": "...", "district": "..."}'
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim(),
      district: _districtController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar(
        message: 'Profile updated successfully!',
        icon: Icons.check_circle_outline,
        color: AppColors.primary,
      );
      Navigator.pop(context, true);
    } else {
      final error = authProvider.errorMessage ?? 'Failed to update profile. Please try again.';
      _showSnackBar(
        message: error,
        icon: Icons.error_outline,
        color: Colors.red.shade700,
        durationSeconds: 4,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
    int durationSeconds = 2,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  // ─── Build UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'edit_profile'.tr(languageCode),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          // Quick save button in AppBar
          TextButton.icon(
            onPressed: (_isSaving || _isUploadingAvatar) ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            label: Text(
              'Save',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Header Photo Card ───────────────────────────────────────
            _buildProfileHeader(user),

            // ─── Form Container ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(user),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header with Avatar Preview ──────────────────────────────────────────────

  Widget _buildProfileHeader(AppUser? user) {
    final avatarUrl = _avatarUrlController.text.trim();
    final displayName = _nameController.text.trim();

    ImageProvider? imageProvider;
    if (_localAvatarBytes != null && _localAvatarBytes!.isNotEmpty) {
      imageProvider = MemoryImage(_localAvatarBytes!);
    } else if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty) {
      imageProvider = FileImage(File(_localAvatarPath!));
    } else if (avatarUrl.isNotEmpty) {
      imageProvider = NetworkImage(avatarUrl);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  color: Colors.white.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(displayName, user),
                        )
                      : _buildFallbackInitial(displayName, user),
                ),
              ),

              // Uploading overlay spinner
              if (_isUploadingAvatar)
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),

              // Camera Edit Badge Button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _showImageSourceSelector,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName.isNotEmpty ? displayName : (user?.name ?? 'User Profile'),
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _phoneController.text.isNotEmpty ? _phoneController.text : 'Account Details',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Photo Actions Pill Row
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildHeaderActionChip(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: _isUploadingAvatar ? null : () => _pickAndUploadImage(ImageSource.camera),
              ),
              _buildHeaderActionChip(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: _isUploadingAvatar ? null : () => _pickAndUploadImage(ImageSource.gallery),
              ),
              _buildHeaderActionChip(
                icon: Icons.link_rounded,
                label: 'URL',
                onTap: _isUploadingAvatar ? null : _showUrlInputDialog,
              ),
            ],
          ),

          if (_isUploadingAvatar)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(color: Colors.yellowAccent, strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading new photo...',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackInitial(String displayName, AppUser? user) {
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U');

    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ─── Form Card ───────────────────────────────────────────────────────────────

  Widget _buildFormCard(AppUser? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Update your public profile details',
                    style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Full Name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'e.g. Rafiq Ahmed',
            icon: Icons.badge_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 18),

          // 2. District
          _buildTextField(
            controller: _districtController,
            label: 'District',
            hintText: 'e.g. Bogura',
            icon: Icons.location_on_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your district' : null,
          ),
          const SizedBox(height: 8),

          // District Quick Chips
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonDistricts.map((district) {
                final isSelected = _districtController.text.trim().toLowerCase() == district.toLowerCase();
                return InkWell(
                  onTap: () {
                    setState(() {
                      _districtController.text = district;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      district,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Avatar URL
          _buildTextField(
            controller: _avatarUrlController,
            label: 'Avatar URL',
            hintText: 'https://cdn.example.com/avatar.jpg',
            icon: Icons.link_rounded,
            suffixIcon: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              tooltip: 'Choose photo / Enter URL',
              onPressed: _showImageSourceSelector,
            ),
          ),
          const SizedBox(height: 18),

          // 4. Phone Number (Read-only Login ID)
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number (Account ID)',
            icon: Icons.lock_outline_rounded,
            readOnly: true,
            helperText: 'Your phone number is your verified login credential and cannot be changed.',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? helperText,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: readOnly ? Colors.grey.shade700 : AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: readOnly ? Colors.grey.shade500 : AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF7F8FA) : const Color(0xFFFAFBFD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 13),
      ),
    );
  }

  // ─── Save Button ─────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_isSaving || _isUploadingAvatar) ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Saving Profile Changes...',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Save Changes',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
