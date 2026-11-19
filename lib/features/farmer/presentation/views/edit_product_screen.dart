import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../data/models/update_product_request_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _customCategoryController;

  late String _unit;
  late TradeType _tradeType;
  late String _category;
  bool _isCustomCategory = false;
  late String _status;

  late DateTime _startTime;
  late DateTime _endTime;

  // Images state
  late String _imageUrl;
  late List<String> _existingImageUrls;
  final List<UploadFileItem> _newSelectedImages = [];
  int _primaryImageIndex = 0;

  bool _isSubmitting = false;
  bool _isDeleting = false;
  String _submissionStatus = '';

  final List<String> _categoryOptions = [
    'rice',
    'vegetables',
    'fruits',
    'grains',
    'spices',
    'custom',
  ];

  final List<String> _statusOptions = [
    'active',
    'inactive',
    'expired',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.productName);
    _quantityController = TextEditingController(
      text: p.quantity % 1 == 0 ? p.quantity.toInt().toString() : p.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: p.minimumPrice % 1 == 0 ? p.minimumPrice.toInt().toString() : p.minimumPrice.toString(),
    );
    _customCategoryController = TextEditingController();

    _unit = p.unit.isNotEmpty ? p.unit : 'KG';
    _tradeType = p.tradeType;

    final lowerCat = p.category.toLowerCase().trim();
    if (_categoryOptions.contains(lowerCat)) {
      _category = lowerCat;
      _isCustomCategory = false;
    } else if (lowerCat.isNotEmpty) {
      _category = 'custom';
      _isCustomCategory = true;
      _customCategoryController.text = lowerCat;
    } else {
      _category = 'rice';
      _isCustomCategory = false;
    }

    _status = p.status.isNotEmpty ? p.status.toLowerCase() : 'active';
    _startTime = p.startTime;
    _endTime = p.endTime;

    _imageUrl = p.imageUrl;
    _existingImageUrls = List<String>.from(
      p.imageUrls.isNotEmpty ? p.imageUrls : (p.imageUrl.isNotEmpty ? [p.imageUrl] : []),
    );
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

  // ─── Image Picking ──────────────────────────────────────────────────────────

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
          _newSelectedImages.add(item);
          _imageUrl = item.path ?? '';
        });
        _showSuccessNotification('New photo captured from camera');
      } else {
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
              _newSelectedImages.addAll(newItems);
              _imageUrl = _newSelectedImages.last.path ?? '';
            });
            _showSuccessNotification('${pickedList.length} photo(s) selected');
            return;
          }
        } catch (_) {}

        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (file == null) return;

        final item = await UploadFileItem.fromXFile(file);
        setState(() {
          _newSelectedImages.add(item);
          _imageUrl = item.path ?? '';
        });
        _showSuccessNotification('Photo selected from gallery');
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access photos: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
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
                    'Change Product Photo',
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
                  subtitle: const Text('Capture with camera'),
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
                    child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select from device photos'),
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
                    child: const Icon(Icons.link_rounded, color: Colors.orange),
                  ),
                  title: const Text('Enter Web Image URL', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste an image URL directly'),
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
    final urlController = TextEditingController(text: _imageUrl.startsWith('http') ? _imageUrl : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Image URL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link),
            border: OutlineInputBorder(),
          ),
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
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _imageUrl = newUrl;
                  _existingImageUrls.insert(0, newUrl);
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

  void _showSuccessNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
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

  // ─── Update (PATCH) ──────────────────────────────────────────────────────────

  Future<void> _updateProduct() async {
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
      _submissionStatus = _newSelectedImages.isNotEmpty
          ? 'Uploading ${_newSelectedImages.length} new photo(s)...'
          : 'Saving changes...';
    });

    final finalCategory = _isCustomCategory
        ? _customCategoryController.text.trim().toLowerCase()
        : _category.trim().toLowerCase();

    final productProvider = context.read<ProductProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        token = await StorageService().getAccessToken();
      }

      List<String> uploadedImageUrls = [];

      // 1. Upload new local images if selected
      if (_newSelectedImages.isNotEmpty) {
        try {
          uploadedImageUrls = await productProvider.uploadImages(
            files: _newSelectedImages,
            token: token,
          );
        } catch (uploadError) {
          debugPrint('⚠️ [EDIT_PRODUCT] Image upload failed: $uploadError');
          throw Exception('Image upload failed: $uploadError');
        }
      }

      setState(() => _submissionStatus = 'Updating product on server...');

      // 2. Compute final image URLs list
      final allUrls = <String>[];
      if (uploadedImageUrls.isNotEmpty) {
        allUrls.addAll(uploadedImageUrls);
      }
      allUrls.addAll(_existingImageUrls);

      final String effectiveImageUrl = allUrls.isNotEmpty
          ? allUrls.first
          : (_imageUrl.isNotEmpty ? _imageUrl : 'https://cdn.example.com/products/rice-updated.jpg');

      final effectiveImageUrls = allUrls.isNotEmpty ? allUrls : [effectiveImageUrl];

      final request = UpdateProductRequestModel(
        productName: _nameController.text.trim(),
        quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
        unit: _unit,
        minimumPrice: double.tryParse(_priceController.text.trim()) ?? 0,
        tradeType: _getTradeTypeString(_tradeType),
        category: finalCategory.isNotEmpty ? finalCategory : 'rice',
        status: _status,
        startTime: _startTime,
        endTime: _endTime,
        imageUrl: effectiveImageUrl,
        imageUrls: effectiveImageUrls,
      );

      final updated = await productProvider.updateProduct(
        id: widget.product.id,
        request: request,
        token: token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Product "${updated.productName}" updated successfully!')),
            ],
          ),
          backgroundColor: AppColors.primary,
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

  // ─── Delete (DELETE) ─────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Listing?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${widget.product.productName}"? This action cannot be undone.',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final token = context.read<AuthProvider>().token;
      final success = await context.read<ProductProvider>().deleteProduct(
            id: widget.product.id,
            token: token,
          );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Listing "${widget.product.productName}" deleted.'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ─── UI Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'Edit Product',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                  )
                : const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Product',
            onPressed: (_isSubmitting || _isDeleting) ? null : _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section ──────────────────────────────────────────
              _buildImageCard(),
              const SizedBox(height: 18),

              // ── General Information Card ───────────────────────────────
              _buildSectionCard(
                title: 'General Information',
                icon: Icons.info_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: _inputDecoration(
                        label: 'Product Name',
                        hint: 'e.g., Boro Rice Premium',
                        icon: Icons.shopping_basket_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
                            decoration: _inputDecoration(
                              label: 'Category',
                              icon: Icons.category_outlined,
                            ),
                            items: _categoryOptions.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(
                                  cat == 'custom' ? 'Custom...' : '${cat[0].toUpperCase()}${cat.substring(1)}',
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
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _customCategoryController,
                              style: GoogleFonts.outfit(fontSize: 14),
                              decoration: _inputDecoration(
                                label: 'Custom Category',
                                hint: 'e.g., lentils',
                              ),
                              validator: (v) {
                                if (_isCustomCategory && (v == null || v.trim().isEmpty)) {
                                  return 'Enter category';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Listing Status',
                        icon: Icons.toggle_on_outlined,
                      ),
                      items: _statusOptions.map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: s == 'active'
                                      ? AppColors.success
                                      : (s == 'inactive' ? Colors.grey : Colors.orange),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${s[0].toUpperCase()}${s.substring(1)}'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Inventory & Pricing Card ───────────────────────────────
              _buildSectionCard(
                title: 'Quantity & Pricing',
                icon: Icons.monetization_on_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            style: GoogleFonts.outfit(fontSize: 14),
                            decoration: _inputDecoration(
                              label: 'Quantity',
                              suffixText: _unit,
                              icon: Icons.scale_outlined,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter quantity';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) return 'Invalid quantity';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownMenu<String>(
                          initialSelection: _unit,
                          width: 110,
                          onSelected: (val) {
                            if (val != null) setState(() => _unit = val);
                          },
                          dropdownMenuEntries: ['KG', 'Tons', 'Monds', 'Bag']
                              .map((u) => DropdownMenuEntry(value: u, label: u))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _priceController,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: _inputDecoration(
                        label: 'Minimum Price / Starting Bid',
                        prefixText: '৳ ',
                        icon: Icons.payments_outlined,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter price';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Trade Configuration Card ───────────────────────────────
              _buildSectionCard(
                title: 'Trade Configuration',
                icon: Icons.handshake_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<TradeType>(
                      segments: const [
                        ButtonSegment(
                          value: TradeType.auction,
                          label: Text('Auction'),
                          icon: Icon(Icons.gavel_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: TradeType.negotiation,
                          label: Text('Negotiation'),
                          icon: Icon(Icons.handshake_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: TradeType.both,
                          label: Text('Both'),
                          icon: Icon(Icons.all_inclusive_rounded, size: 16),
                        ),
                      ],
                      selected: {_tradeType},
                      onSelectionChanged: (v) => setState(() => _tradeType = v.first),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _tradeType == TradeType.auction
                          ? 'Buyers will bid openly. Highest eligible bid can be accepted.'
                          : _tradeType == TradeType.negotiation
                              ? 'Buyers submit private price offers that you can review.'
                              : 'Supports both competitive bidding and direct private offers.',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Timeline Schedule Card ─────────────────────────────────
              _buildSectionCard(
                title: 'Schedule & Duration',
                icon: Icons.date_range_outlined,
                child: Column(
                  children: [
                    _buildDateTimeTile(
                      label: 'Start Time',
                      dateTimeStr: dateFormat.format(_startTime),
                      icon: Icons.play_circle_outline_rounded,
                      color: AppColors.primary,
                      onTap: () async {
                        final picked = await _pickDateTime(_startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                    ),
                    const Divider(height: 1),
                    _buildDateTimeTile(
                      label: 'End / Expiry Time',
                      dateTimeStr: dateFormat.format(_endTime),
                      icon: Icons.stop_circle_outlined,
                      color: Colors.orange.shade800,
                      onTap: () async {
                        final picked = await _pickDateTime(_endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Save Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _updateProduct,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _submissionStatus.isNotEmpty ? _submissionStatus : 'Saving...',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Image Card Component ──────────────────────────────────────────────────

  Widget _buildImageCard() {
    final previewUrl = _newSelectedImages.isNotEmpty
        ? (_newSelectedImages[_primaryImageIndex].path ?? '')
        : _imageUrl;

    final totalImagesCount = _newSelectedImages.length + _existingImageUrls.length;

    return Container(
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
          // Main Preview
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: ProductImageView(
                  imageUrl: previewUrl,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: ElevatedButton.icon(
                  onPressed: _showImageSourceSelector,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: Text('Change Photo', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_newSelectedImages.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'New Photo Selected',
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Thumbnails row if multiple images exist or selected
          if (totalImagesCount > 1 || _newSelectedImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // New selected images
                    for (int i = 0; i < _newSelectedImages.length; i++)
                      _buildThumbItem(
                        url: _newSelectedImages[i].path ?? '',
                        isNew: true,
                        onRemove: () {
                          setState(() {
                            _newSelectedImages.removeAt(i);
                            if (_primaryImageIndex >= _newSelectedImages.length) {
                              _primaryImageIndex = 0;
                            }
                          });
                        },
                      ),
                    // Existing images
                    for (int i = 0; i < _existingImageUrls.length; i++)
                      _buildThumbItem(
                        url: _existingImageUrls[i],
                        isNew: false,
                        onRemove: _existingImageUrls.length > 1
                            ? () {
                                setState(() {
                                  _existingImageUrls.removeAt(i);
                                  if (_imageUrl == _existingImageUrls.first) {
                                    _imageUrl = _existingImageUrls.isNotEmpty ? _existingImageUrls.first : '';
                                  }
                                });
                              }
                            : null,
                      ),
                    // Add more button
                    InkWell(
                      onTap: _showImageSourceSelector,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbItem({required String url, required bool isNew, VoidCallback? onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ProductImageView(
              imageUrl: url,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primary) : null,
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required String dateTimeStr,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
      subtitle: Text(
        dateTimeStr,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.black54),
      ),
      onTap: onTap,
    );
  }
}
