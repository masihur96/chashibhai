import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../data/models/create_product_request_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _customCategoryController;

  String _unit = 'KG';
  TradeType _tradeType = TradeType.both;
  String _category = 'rice';
  bool _isCustomCategory = false;

  late DateTime _startTime;
  late DateTime _endTime;

  // Image states
  String _imageUrl = 'https://cdn.example.com/products/rice.jpg';
  final List<UploadFileItem> _selectedImages = [];
  int _primaryImageIndex = 0;
  String _imageSourceType =
      'default'; // 'default', 'camera', 'gallery', 'network', 'preset'

  bool _isSubmitting = false;
  String _submissionStatus = '';

  final List<String> _categoryOptions = [
    'rice',
    'vegetables',
    'fruits',
    'grains',
    'spices',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with defaults matching the curl request
    _nameController = TextEditingController(text: 'Boro Rice');
    _quantityController = TextEditingController(text: '500');
    _priceController = TextEditingController(text: '45');
    _customCategoryController = TextEditingController();

    // Default start time: 2026-11-20 08:00 (or current date/time)
    final now = DateTime.now();
    _startTime = DateTime(now.year, now.month, now.day, 8, 0);
    _endTime = _startTime.add(const Duration(days: 5, hours: 12));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime current) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null || !mounted) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
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
          _primaryImageIndex = _selectedImages.length - 1;
          _imageUrl = item.path ?? '';
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
              _imageUrl = _selectedImages[_primaryImageIndex].path ?? '';
              _imageSourceType = 'gallery';
            });
            _showSuccessNotification(
              '${pickedList.length} photo(s) selected from gallery!',
            );
            return;
          }
        } catch (_) {
          // If pickMultiImage is unsupported or throws on platform, fallback to single pickImage
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
          _primaryImageIndex = _selectedImages.length - 1;
          _imageUrl = item.path ?? '';
          _imageSourceType = 'gallery';
        });

        _showSuccessNotification('Photo selected from gallery!');
      }
    } on PlatformException catch (e) {
      debugPrint(
        '⚠️ [IMAGE_PICKER] PlatformException ($source): code=${e.code}, message=${e.message}',
      );

      // If camera is unsupported (e.g. on iOS simulator or device without camera), fall back to gallery
      if (source == ImageSource.camera) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera unavailable on simulator/device. Opening Gallery instead...',
              ),
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
            'Native plugin not registered. Since image_picker was just added, please fully stop and re-run the app (hot reload cannot register new native plugins).';
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
                Text(
                  'Image Picker Note',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userFriendlyMessage),
                const SizedBox(height: 12),
                const Text(
                  'Would you like to select from presets or enter an image URL instead?',
                ),
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
                  _showImagePickerDialog();
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
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_primaryImageIndex >= _selectedImages.length) {
        _primaryImageIndex = _selectedImages.isEmpty
            ? 0
            : _selectedImages.length - 1;
      }
      if (_selectedImages.isEmpty) {
        _imageUrl = 'https://cdn.example.com/products/rice.jpg';
        _imageSourceType = 'default';
      } else {
        _imageUrl = _selectedImages[_primaryImageIndex].path ?? '';
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
      _imageUrl = _selectedImages[index].path ?? '';
    });
  }

  /// Opens the Bottom Sheet to choose between Camera, Gallery, or Custom URL
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
                    'Product Images',
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
                  subtitle: const Text('Select one or more photos from device'),
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
                    _showImagePickerDialog();
                  },
                ),
                if (_selectedImages.isNotEmpty ||
                    _imageSourceType != 'default') ...[
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
                      'Reset to Default',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Clear selected photos and reset to sample image',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _imageUrl = 'https://cdn.example.com/products/rice.jpg';
                        _selectedImages.clear();
                        _primaryImageIndex = 0;
                        _imageSourceType = 'default';
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

  void _showImagePickerDialog() {
    final urlController = TextEditingController(
      text: _imageUrl.startsWith('http') || _imageUrl.startsWith('assets')
          ? _imageUrl
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Product Photo URL',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Presets:',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.grain, size: 16),
                    label: const Text('Boro Rice (CDN)'),
                    onPressed: () {
                      urlController.text =
                          'https://cdn.example.com/products/rice.jpg';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.rice_bowl, size: 16),
                    label: const Text('Rice Asset'),
                    onPressed: () {
                      urlController.text = 'assets/images/rice.png';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.eco, size: 16),
                    label: const Text('Tomato'),
                    onPressed: () {
                      urlController.text = 'assets/images/tomato.png';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.circle, size: 16),
                    label: const Text('Potato'),
                    onPressed: () {
                      urlController.text = 'assets/images/potato.png';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.spa, size: 16),
                    label: const Text('Onion'),
                    onPressed: () {
                      urlController.text = 'assets/images/onion.png';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _imageUrl = newUrl;
                  _selectedImages.clear();
                  _primaryImageIndex = 0;
                  _imageSourceType = newUrl.startsWith('http')
                      ? 'network'
                      : 'preset';
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getTradeTypeString(TradeType type) {
    switch (type) {
      case TradeType.auction:
        return 'auction';
      case TradeType.negotiation:
        return 'negotiation';
      case TradeType.both:
        return 'both';
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionStatus = _selectedImages.isNotEmpty
          ? 'Uploading ${_selectedImages.length} image(s)...'
          : 'Publishing listing...';
    });

    final finalCategory = _isCustomCategory
        ? _customCategoryController.text.trim().toLowerCase()
        : _category.trim().toLowerCase();

    final productProvider = context.read<ProductProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      // Fetch stored token if available
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        token = await StorageService().getAccessToken();
      }

      List<String> uploadedImageUrls = [];

      // 1. Upload local images via POST /api/v1/upload if any are selected
      if (_selectedImages.isNotEmpty) {
        debugPrint(
          '🚀 [ADD_PRODUCT] Uploading ${_selectedImages.length} images to /api/v1/upload...',
        );
        setState(
          () => _submissionStatus =
              'Uploading ${_selectedImages.length} image(s)...',
        );

        try {
          uploadedImageUrls = await productProvider.uploadImages(
            files: _selectedImages,
            token: token,
          );
          debugPrint(
            '✅ [ADD_PRODUCT] Image upload response URLs: $uploadedImageUrls',
          );
        } catch (uploadError) {
          debugPrint('⚠️ [ADD_PRODUCT] Image upload failed: $uploadError');
          throw Exception('Image upload failed: $uploadError');
        }
      }

      setState(() => _submissionStatus = 'Creating product listing...');

      // 2. Prepare effective image URLs
      final String effectiveImageUrl;
      final List<String> effectiveImageUrls;

      if (uploadedImageUrls.isNotEmpty) {
        effectiveImageUrl = uploadedImageUrls.first;
        effectiveImageUrls = uploadedImageUrls;
      } else {
        effectiveImageUrl = _imageUrl;
        effectiveImageUrls = [_imageUrl];
      }

      final request = CreateProductRequestModel(
        productName: _nameController.text.trim(),
        quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
        unit: _unit,
        minimumPrice: double.tryParse(_priceController.text.trim()) ?? 0,
        tradeType: _getTradeTypeString(_tradeType),
        category: finalCategory.isNotEmpty ? finalCategory : 'rice',
        startTime: _startTime,
        endTime: _endTime,
        imageUrl: effectiveImageUrl,
        imageUrls: effectiveImageUrls,
      );

      final createdProduct = await productProvider.createProduct(
        request: request,
        token: token,
      );

      if (!mounted) return;

      // Retain local image reference in provider's memory product if local photo was chosen
      if (_selectedImages.isNotEmpty) {
        final localProduct = createdProduct.copyWith(
          imageUrl:
              _selectedImages[_primaryImageIndex].path ??
              createdProduct.imageUrl,
          imageUrls: effectiveImageUrls,
        );
        final products = productProvider.products;
        final idx = products.indexWhere((p) => p.id == createdProduct.id);
        if (idx != -1) {
          products[idx] = localProduct;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Product "${createdProduct.productName}" listed successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rawError),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'List Offline',
            textColor: Colors.white,
            onPressed: () {
              final offlineProduct = Product(
                id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                farmerId: context.read<AuthProvider>().currentUser?.id ?? 'f1',
                productName: _nameController.text.trim(),
                imageUrl: _selectedImages.isNotEmpty
                    ? (_selectedImages[_primaryImageIndex].path ?? _imageUrl)
                    : _imageUrl,
                imageUrls: _selectedImages.isNotEmpty
                    ? _selectedImages.map((i) => i.path ?? '').toList()
                    : [_imageUrl],
                quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
                unit: _unit,
                minimumPrice:
                    double.tryParse(_priceController.text.trim()) ?? 0,
                tradeType: _tradeType,
                startTime: _startTime,
                endTime: _endTime,
                category: finalCategory.isNotEmpty ? finalCategory : 'rice',
                status: 'active',
              );
              context.read<ProductProvider>().addProduct(offlineProduct);
              Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List New Product',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              Text(
                'Product Details',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Boro Rice',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter product name'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: _categoryOptions.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat == 'custom'
                                ? 'Custom...'
                                : '${cat[0].toUpperCase()}${cat.substring(1)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _category = val;
                            _isCustomCategory = val == 'custom';
                          });
                        }
                      },
                    ),
                  ),
                  if (_isCustomCategory) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _customCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Category',
                          hintText: 'e.g., rice',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) {
                          if (_isCustomCategory &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Enter category';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        suffixText: _unit,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter quantity';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Invalid quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownMenu<String>(
                    initialSelection: _unit,
                    width: 110,
                    onSelected: (String? value) {
                      if (value != null) {
                        setState(() => _unit = value);
                      }
                    },
                    dropdownMenuEntries: ['KG', 'Tons', 'Monds', 'Bag']
                        .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                            value: value,
                            label: value,
                          );
                        })
                        .toList(),
                  ),
                ],
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
              SegmentedButton<TradeType>(
                segments: const [
                  ButtonSegment(
                    value: TradeType.auction,
                    label: Text('Auction'),
                    icon: Icon(Icons.gavel),
                  ),
                  ButtonSegment(
                    value: TradeType.negotiation,
                    label: Text('Negotiation'),
                    icon: Icon(Icons.handshake),
                  ),
                  ButtonSegment(
                    value: TradeType.both,
                    label: Text('Both'),
                    icon: Icon(Icons.all_inclusive),
                  ),
                ],
                selected: {_tradeType},
                onSelectionChanged: (v) => setState(() => _tradeType = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: _tradeType == TradeType.auction
                      ? 'Minimum Bid Price'
                      : 'Minimum Price / Asking Price',
                  prefixText: '৳ ',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter price';
                  final num = double.tryParse(v);
                  if (num == null || num <= 0) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Schedule Listing',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFF2E7D32),
                        ),
                        title: const Text('Start Time'),
                        subtitle: Text(dateFormat.format(_startTime)),
                        trailing: const Icon(Icons.edit_calendar, size: 20),
                        onTap: () async {
                          final picked = await _pickDateTime(_startTime);
                          if (picked != null) {
                            setState(() => _startTime = picked);
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.orange,
                        ),
                        title: const Text('End Time'),
                        subtitle: Text(dateFormat.format(_endTime)),
                        trailing: const Icon(Icons.edit_calendar, size: 20),
                        onTap: () async {
                          final picked = await _pickDateTime(_endTime);
                          if (picked != null) {
                            setState(() => _endTime = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitProduct,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _submissionStatus.isNotEmpty
                                  ? _submissionStatus
                                  : 'Publishing...',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Publish Listing',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageHeader(),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildThumbnailsList(),
        ],
      ],
    );
  }

  Widget _buildThumbnailsList() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            // Add More Button
            return InkWell(
              onTap: _showImageSourceSelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final isPrimary = index == _primaryImageIndex;
          final item = _selectedImages[index];

          return Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () => _setPrimaryImage(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPrimary
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                      width: isPrimary ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    item.bytes,
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
              if (isPrimary)
                Positioned(
                  bottom: 2,
                  left: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'COVER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: -6,
                right: -6,
                child: InkWell(
                  onTap: () => _removeSelectedImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageHeader() {
    IconData sourceIcon;
    String sourceLabel;

    if (_selectedImages.isNotEmpty) {
      sourceIcon = Icons.photo_library;
      sourceLabel =
          '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} attached';
    } else {
      switch (_imageSourceType) {
        case 'camera':
          sourceIcon = Icons.camera_alt;
          sourceLabel = 'Captured from Camera';
          break;
        case 'gallery':
          sourceIcon = Icons.photo_library;
          sourceLabel = 'Selected from Gallery';
          break;
        case 'network':
          sourceIcon = Icons.cloud;
          sourceLabel = 'Custom Web URL';
          break;
        default:
          sourceIcon = Icons.image;
          sourceLabel = 'Default Sample Image';
      }
    }

    final Uint8List? activeImageBytes = _selectedImages.isNotEmpty
        ? _selectedImages[_primaryImageIndex].bytes
        : null;

    return InkWell(
      onTap: _showImageSourceSelector,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeImageBytes != null
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade300,
            width: activeImageBytes != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageView(
              imageUrl: activeImageBytes != null ? '' : _imageUrl,
              imageBytes: activeImageBytes,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            // Top badge: source
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sourceIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      sourceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom action row
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedImages.isNotEmpty
                              ? '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} ready to upload'
                              : 'Upload Product Photo',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _selectedImages.isNotEmpty
                              ? 'Tap to add more photos or change'
                              : 'Tap to pick from gallery, camera, or URL',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedImages.isNotEmpty ? 'Manage' : 'Pick Photo',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
