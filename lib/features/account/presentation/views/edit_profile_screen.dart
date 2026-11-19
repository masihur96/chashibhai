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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Profile Photo',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture with camera & upload'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select from device photos & upload'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.link_rounded, color: Colors.orange),
                  ),
                  title: const Text('Enter Image URL', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste a web URL or select sample'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Avatar URL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tempController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sample Presets:',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Sample Avatar 1'),
                  onPressed: () {
                    tempController.text =
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400';
                  },
                ),
                ActionChip(
                  label: const Text('Sample Avatar 2'),
                  onPressed: () {
                    tempController.text =
                        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
            child: const Text('Apply'),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
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
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(user),
                    const SizedBox(height: 28),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: 116,
                          height: 116,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(displayName, user),
                        )
                      : _buildFallbackInitial(displayName, user),
                ),
              ),

              // Uploading overlay spinner
              if (_isUploadingAvatar)
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),

              // Camera Edit Button
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
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
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
            displayName.isNotEmpty ? displayName : 'Farmer User',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _phoneController.text.isNotEmpty ? _phoneController.text : 'Account Profile',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (_isUploadingAvatar)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Uploading new photo...',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personal Information',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'e.g. Rafiq Ahmed',
            icon: Icons.badge_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),

          // District
          _buildTextField(
            controller: _districtController,
            label: 'District',
            hintText: 'e.g. Bogura',
            icon: Icons.location_on_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your district' : null,
          ),
          const SizedBox(height: 16),

          // Avatar URL
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
          const SizedBox(height: 16),

          // Phone Number (Read-only)
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number (Account ID)',
            icon: Icons.phone_outlined,
            readOnly: true,
            helperText: 'Phone number cannot be changed as it is your login ID.',
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
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
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
                    'Saving Profile...',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Text(
                'Save Changes',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
