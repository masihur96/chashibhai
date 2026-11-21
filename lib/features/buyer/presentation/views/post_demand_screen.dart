import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/state/auth_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../state/demand_provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../group/presentation/views/groups_list_screen.dart';
import '../../data/models/create_demand_request_model.dart';

class PostDemandScreen extends StatefulWidget {
  const PostDemandScreen({super.key});

  @override
  State<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends State<PostDemandScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _callingPriceController;
  late final TextEditingController _locationController;
  late final TextEditingController _imageUrlController;

  String _imageUrl = 'https://cdn.example.com/demands/potato.jpg';
  List<String> _selectedBuyerIds = [];
  bool _isInit = false;
  late DateTime _expiryDate;
  TradeType _tradeType = TradeType.both;
  bool _isSubmitting = false;

  // Image picking & upload state
  final ImagePicker _picker = ImagePicker();
  final List<UploadFileItem> _selectedImages = [];
  bool _isUploadingImage = false;
  String _submissionStatus = '';
  String _imageSourceType = 'curl_default'; // 'camera', 'gallery', 'preset', 'curl_default', 'uploaded'

  // Group buying state
  bool _isGroupDemand = false;
  BuyingGroup? _selectedGroup;

  @visibleForTesting
  void setSelectedImagesForTesting(List<UploadFileItem> items) {
    setState(() {
      _selectedImages.clear();
      _selectedImages.addAll(items);
      _imageSourceType = 'gallery';
    });
  }

  @override
  void initState() {
    super.initState();
    // Default initial values pre-populated with curl specifications
    _nameController = TextEditingController(text: 'Potatoes (Diamant)');
    _quantityController = TextEditingController(text: '1000');
    _callingPriceController = TextEditingController(text: '28');
    _locationController = TextEditingController(text: 'Karwan Bazar, Dhaka');
    _imageUrl = 'https://cdn.example.com/demands/potato.jpg';
    _imageUrlController = TextEditingController(text: _imageUrl);
    _tradeType = TradeType.both;
    _expiryDate = DateTime.tryParse('2026-11-30T18:00:00Z')?.toLocal() ??
        DateTime(2026, 11, 30, 18, 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _callingPriceController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _resetToCurlDefaults() {
    setState(() {
      _nameController.text = 'Potatoes (Diamant)';
      _quantityController.text = '1000';
      _callingPriceController.text = '28';
      _locationController.text = 'Karwan Bazar, Dhaka';
      _imageUrl = 'https://cdn.example.com/demands/potato.jpg';
      _imageUrlController.text = _imageUrl;
      _selectedImages.clear();
      _imageSourceType = 'curl_default';
      _tradeType = TradeType.both;
      _expiryDate = DateTime.tryParse('2026-11-30T18:00:00Z')?.toLocal() ??
          DateTime(2026, 11, 30, 18, 0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form reset to curl specification defaults.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Picks image(s) from Camera or Gallery for multipart upload
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (file == null) return;

        final item = await UploadFileItem.fromXFile(file);
        setState(() {
          _selectedImages.add(item);
          _imageSourceType = 'camera';
        });

        _showSuccessNotification('Photo captured from camera!');
      } else {
        // Try picking multiple images from gallery
        try {
          final List<XFile> pickedList = await _picker.pickMultiImage(
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );

          if (pickedList.isNotEmpty) {
            final List<UploadFileItem> newItems = [];
            for (final f in pickedList) {
              newItems.add(await UploadFileItem.fromXFile(f));
            }
            setState(() {
              _selectedImages.addAll(newItems);
              _imageSourceType = 'gallery';
            });
            _showSuccessNotification(
              '${pickedList.length} photo(s) selected from gallery!',
            );
            return;
          }
        } catch (_) {
          // Fallback to single pickImage if pickMultiImage fails on platform
        }

        // Single image picker fallback
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (file == null) return;

        final item = await UploadFileItem.fromXFile(file);
        setState(() {
          _selectedImages.add(item);
          _imageSourceType = 'gallery';
        });

        _showSuccessNotification('Photo selected from gallery!');
      }
    } on PlatformException catch (e) {
      debugPrint('⚠️ [IMAGE_PICKER] PlatformException ($source): ${e.code} ${e.message}');
      if (source == ImageSource.camera) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera unavailable on device. Opening Gallery instead...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        await _pickImage(ImageSource.gallery);
        return;
      }

      String userFriendlyMessage;
      if (e.code == 'camera_access_denied') {
        userFriendlyMessage =
            'Camera access was denied. Please allow camera permissions in device settings.';
      } else if (e.code == 'photo_access_denied') {
        userFriendlyMessage =
            'Photo access was denied. Please allow photo gallery permissions in device settings.';
      } else if (e.code.contains('channel') ||
          e.message?.contains('channel') == true ||
          e.code == 'MissingPluginException') {
        userFriendlyMessage =
            'Native plugin not registered. Since image_picker was just added, please fully stop and re-run the app.';
      } else {
        userFriendlyMessage =
            'Could not access device photos (${e.code}): ${e.message ?? 'Unknown error'}';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Image Picker Note',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userFriendlyMessage),
                const SizedBox(height: 12),
                const Text('Would you like to select from presets or enter an image URL instead?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _showEditImageUrlDialog(context);
                },
                child: const Text('Choose Preset / URL'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Uploads selected images immediately before publishing
  Future<void> _uploadSelectedImagesNow() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImage = true;
      _submissionStatus = 'Uploading ${_selectedImages.length} image(s)...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final demandProvider = context.read<DemandProvider>();
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        try {
          token = await StorageService().getAccessToken();
        } catch (_) {}
      }

      final filesToUpload = List<UploadFileItem>.from(_selectedImages);
      final uploadedUrls = await demandProvider.uploadImages(
        files: filesToUpload,
        token: token,
      );

      if (uploadedUrls.isNotEmpty) {
        final firstUrl = uploadedUrls.first;
        setState(() {
          _imageUrl = firstUrl;
          _imageUrlController.text = firstUrl;
          _selectedImages.clear();
          _imageSourceType = 'uploaded';
        });

        _showSuccessNotification('Image uploaded successfully: $firstUrl');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _submissionStatus = '';
        });
      }
    }
  }

  Future<void> _submitDemand() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isGroupDemand && _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a buying group first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionStatus = 'Preparing demand...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final demandProvider = context.read<DemandProvider>();
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        try {
          token = await StorageService().getAccessToken();
        } catch (_) {}
      }
      if (!mounted) return;

      String effectiveImageUrl = _imageUrl;

      // 1. Upload local images via POST /api/v1/upload if any are selected
      if (_selectedImages.isNotEmpty) {
        setState(() => _submissionStatus = 'Uploading ${_selectedImages.length} image(s)...');
        try {
          final filesToUpload = List<UploadFileItem>.from(_selectedImages);
          final uploadedUrls = await demandProvider.uploadImages(
            files: filesToUpload,
            token: token,
          );
          if (uploadedUrls.isNotEmpty) {
            effectiveImageUrl = uploadedUrls.first;
            _imageUrl = effectiveImageUrl;
            _imageUrlController.text = effectiveImageUrl;
            _selectedImages.clear();
            _imageSourceType = 'uploaded';
          }
        } catch (uploadError) {
          debugPrint('⚠️ [POST_DEMAND] Image upload failed: $uploadError');
          throw Exception('Image upload failed: $uploadError');
        }
      }

      // Synchronize latest access token in case token was refreshed during upload
      try {
        final latestToken = await StorageService().getAccessToken();
        if (latestToken != null && latestToken.isNotEmpty) {
          token = latestToken;
        }
      } catch (_) {}

      setState(() => _submissionStatus = 'Publishing demand...');

      final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
      final price = double.tryParse(_callingPriceController.text.trim()) ?? 0;

      final request = CreateDemandRequestModel(
        productName: _nameController.text.trim(),
        quantity: qty,
        callingPrice: price,
        deliveryLocation: _locationController.text.trim(),
        expiryTime: _expiryDate,
        tradeType: _tradeType.name.toLowerCase(),
        imageUrl: effectiveImageUrl.isNotEmpty
            ? effectiveImageUrl
            : 'https://cdn.example.com/demands/potato.jpg',
      );

      final demand = await demandProvider.createDemand(
        request: request,
        token: token,
      );

      if (!mounted) return;
      final suffix = _isGroupDemand && _selectedGroup != null
          ? ' via group "${_selectedGroup!.name}"'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demand for "${demand.productName}" posted$suffix! Farmers will now see your request.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context, demand);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish demand: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Demo Save',
            textColor: Colors.white,
            onPressed: () {
              final offlineDemand = DemandPost(
                id: 'd_${DateTime.now().millisecondsSinceEpoch}',
                buyerId: context.read<AuthProvider>().currentUser?.id ?? 'u1',
                productName: _nameController.text.trim(),
                quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
                callingPrice: double.tryParse(_callingPriceController.text.trim()) ?? 0,
                deliveryLocation: _locationController.text.trim(),
                expiryTime: _expiryDate,
                status: DemandStatus.active,
                tradeType: _tradeType,
                imageUrl: _imageUrl.isNotEmpty
                    ? _imageUrl
                    : 'https://cdn.example.com/demands/potato.jpg',
              );
              context.read<DemandProvider>().addDemand(offlineDemand);
              Navigator.pop(context, offlineDemand);
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionStatus = '';
        });
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
                    'Demand Product Image',
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
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Capture photo with camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Select photos from your device'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.link, color: Colors.orange),
                  ),
                  title: const Text(
                    'Enter Image URL / Presets',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Paste a web URL or choose demo presets',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditImageUrlDialog(context);
                  },
                ),
                if (_selectedImages.isNotEmpty ||
                    _imageUrl != 'https://cdn.example.com/demands/potato.jpg') ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restart_alt, color: Colors.red),
                    ),
                    title: const Text(
                      'Reset to Curl Default',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Reset to https://cdn.example.com/demands/potato.jpg'),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedImages.clear();
                        _imageUrl = 'https://cdn.example.com/demands/potato.jpg';
                        _imageUrlController.text = _imageUrl;
                        _imageSourceType = 'curl_default';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditImageUrlDialog(BuildContext context) {
    _imageUrlController.text = _imageUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Product Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Potato (Curl Default)'),
                  onPressed: () {
                    _imageUrlController.text =
                        'https://cdn.example.com/demands/potato.jpg';
                  },
                ),
                ActionChip(
                  label: const Text('Rice'),
                  onPressed: () {
                    _imageUrlController.text =
                        'https://cdn.example.com/demands/rice.jpg';
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
            onPressed: () {
              setState(() {
                _imageUrl = _imageUrlController.text.trim();
                _selectedImages.clear();
                _imageSourceType = 'preset';
              });
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final myGroups = context
        .watch<GroupProvider>()
        .getMyGroups(context.watch<AuthProvider>().currentUser?.id);
    final allGroups = context.watch<GroupProvider>().groups;
    final openGroups =
        allGroups.where((g) => g.status == GroupBuyStatus.open).toList();

    if (!_isInit) {
      _selectedBuyerIds = [user?.id ?? 'u1'];
      _isInit = true;
    }

    final List<Map<String, String>> buyers = [
      if (user != null)
        {'id': user.id, 'name': '${user.name} (You)'}
      else
        {'id': 'u1', 'name': 'Guest User'},
      {'id': 'u2', 'name': 'Karim (Wholesaler)'},
      {'id': 'u3', 'name': 'Rahim (Retailer)'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Buying Demand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Curl Defaults',
            onPressed: _resetToCurlDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidanceCard(),
              const SizedBox(height: 24),
              Text(
                'Demand Type',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDemandTypeToggle(),
              const SizedBox(height: 20),

              // Conditional: Individual buyer selection or Group picker
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isGroupDemand
                    ? _buildGroupSelector(context, openGroups, myGroups)
                    : _buildBuyerSelector(context, buyers),
              ),

              const SizedBox(height: 20),
              Text(
                'Demand Specifications',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'What product do you need?',
                  hintText: 'e.g., Potatoes (Diamant)',
                  prefixIcon: Icon(Icons.search),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity Needed',
                        suffixText: 'KG',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Enter quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _callingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Calling Price',
                        prefixText: '৳ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Enter price';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Location',
                  hintText: 'e.g., Karwan Bazar, Dhaka',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Trade Configuration',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TradeType>(
                initialValue: _tradeType,
                decoration: const InputDecoration(
                  labelText: 'Trade Type',
                  prefixIcon: Icon(Icons.handshake_outlined),
                ),
                items: TradeType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _tradeType = val);
                },
              ),
              const SizedBox(height: 16),
              // Demand Product Image Picker & Preview
              _buildImagePickerSection(),
              const SizedBox(height: 24),
              Text(
                'Timeline',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                leading: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Demand Expiry'),
                subtitle: Text(
                  'Expires on ${DateFormat('MMM dd, yyyy HH:mm').format(_expiryDate)}',
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    if (!context.mounted) return;
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_expiryDate),
                    );
                    final time = selectedTime ?? TimeOfDay.fromDateTime(_expiryDate);
                    setState(() {
                      _expiryDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isUploadingImage ? null : _submitDemand,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            if (_submissionStatus.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _submissionStatus,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          'Publish Demand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Note: Full amount will be locked in escrow once you accept a farmer\'s offer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    final bool hasSelectedImages = _selectedImages.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSelectedImages ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          width: hasSelectedImages ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSelectedImages ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
                size: 20,
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              Text(
                'Product Image',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasSelectedImages)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedImages.length} image(s) picked',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                )
              else if (_imageSourceType == 'uploaded')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Uploaded',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Default / Preset',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Content body
          if (hasSelectedImages) ...[
            // Local picked image preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey.shade200,
                    child: Image.memory(
                      _selectedImages.first.bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedImages.first.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedImages.first.bytes.length / 1024).toStringAsFixed(1)} KB • ${_selectedImages.first.mimeType}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Will be uploaded to POST /api/v1/upload upon publishing.',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actions row for picked images
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadSelectedImagesNow,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: Text(
                      _isUploadingImage ? 'Uploading...' : 'Upload Now',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _showImageSourceSelector,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove selected image',
                  onPressed: _isUploadingImage
                      ? null
                      : () {
                          setState(() {
                            _selectedImages.clear();
                            _imageSourceType = 'curl_default';
                          });
                        },
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
              ],
            ),
          ] else ...[
            // Default or URL image preview
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey.shade100,
                    child: ProductImageView(
                      imageUrl: _imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _imageSourceType == 'uploaded'
                            ? 'Uploaded Image URL'
                            : 'Default Image URL',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _imageUrl.isNotEmpty ? _imageUrl : 'No URL provided',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _showImageSourceSelector,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: const Text('Pick Image', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditImageUrlDialog(context),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('URL', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemandTypeToggle() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Individual'),
            icon: Icon(Icons.person_outline),
          ),
          ButtonSegment(
            value: true,
            label: Text('Group Buy'),
            icon: Icon(Icons.groups_outlined),
          ),
        ],
        selected: {_isGroupDemand},
        onSelectionChanged: (Set<bool> newSelection) {
          setState(() => _isGroupDemand = newSelection.first);
        },
      ),
    );
  }

  // _toggleOption removed in favor of SegmentedButton

  Widget _buildBuyerSelector(BuildContext context, List<Map<String, String>> buyers) {
    return Column(
      key: const ValueKey('individual'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Co-Buyers (Optional)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showMultiSelectDialog(context, buyers),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select Buyers',
              prefixIcon: Icon(Icons.group_add_outlined),
            ),
            isEmpty: _selectedBuyerIds.isEmpty,
            child: _selectedBuyerIds.isEmpty
                ? const Text('Tap to select buyers...', style: TextStyle(color: Colors.grey, fontSize: 16))
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedBuyerIds.map((id) {
                      final b = buyers.firstWhere((b) => b['id'] == id, orElse: () => {'name': 'Unknown'});
                      return Chip(
                        label: Text(b['name']!, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selectedBuyerIds.remove(id)),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSelector(BuildContext context, List<BuyingGroup> openGroups, List<BuyingGroup> myGroups) {
    return Column(
      key: const ValueKey('group'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Buying Group', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Info chip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer, 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Group buying lets multiple buyers pool orders for bulk price discounts from farmers.', 
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Selected group display
        if (_selectedGroup != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedGroup!.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      Text(
                        '${_selectedGroup!.members.length} members • ${_selectedGroup!.filledQuantity.toInt()}/${_selectedGroup!.targetQuantity.toInt()} KG filled',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedGroup = null),
                  child: const Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              ],
            ),
          ),
        // Group picker button
        OutlinedButton.icon(
          onPressed: () => _showGroupPickerSheet(context, openGroups, myGroups),
          icon: Icon(Icons.group_add_outlined, color: Theme.of(context).colorScheme.primary),
          label: Text(_selectedGroup == null ? 'Choose or Create a Group' : 'Change Group'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  void _showGroupPickerSheet(BuildContext context, List<BuyingGroup> openGroups, List<BuyingGroup> myGroups) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('Select a Group', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen()));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create New'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: openGroups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off_outlined, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No open groups available', style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen()));
                              },
                              child: const Text('Browse & Create Groups'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: openGroups.length,
                        itemBuilder: (context, index) {
                          final g = openGroups[index];
                          final isSelected = _selectedGroup?.id == g.id;
                          final progress = g.filledQuantity / g.targetQuantity;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedGroup = g);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2E7D32).withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200]!,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.groups, color: isSelected ? const Color(0xFF2E7D32) : Colors.grey),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(g.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text('${g.productName} • ${g.members.length} members', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${g.filledQuantity.toInt()}/${g.targetQuantity.toInt()} KG', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('৳${g.pricePerKg}/KG', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF2E7D32))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiSelectDialog(BuildContext context, List<Map<String, String>> buyers) {
    List<String> tempSelected = List.from(_selectedBuyerIds);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredBuyers = buyers.where((b) => b['name']!.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Buyers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search buyers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) => setModalState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredBuyers.length,
                        itemBuilder: (context, index) {
                          final buyer = filteredBuyers[index];
                          final isSelected = tempSelected.contains(buyer['id']);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(buyer['name']!),
                            value: isSelected,
                            activeColor: const Color(0xFF2E7D32),
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(buyer['id']!);
                                } else {
                                  tempSelected.remove(buyer['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedBuyerIds = tempSelected);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Specify your price and quantity. Verified farmers will compete to fulfill your demand.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
