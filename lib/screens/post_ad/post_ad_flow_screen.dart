import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_messenger.dart';
import '../../core/config/nigeria_states.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';

class PostAdFlowScreen extends StatefulWidget {
  const PostAdFlowScreen({super.key});

  @override
  State<PostAdFlowScreen> createState() => _PostAdFlowScreenState();
}

class _PostAdFlowScreenState extends State<PostAdFlowScreen> {
  int _step = 0; // 0,1,2 -> Step 1/2/3

  // Step 1 state
  ListingType _listingType = ListingType.product;
  String? _propertyMode; // 'rent' | 'sale'
  Category? _selectedCategory;
  List<Category> _categories = [];

  // Step 2 state
  final List<File> _photos = [];
  final _picker = ImagePicker();

  // Step 3 state (shared)
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceUnitController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedState; // required by ListingController::store()

  // Step 3 — property-only fields
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _sqftController = TextEditingController();
  String _furnishing = 'Unfurnished';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryService().getCategories();
    setState(() => _categories = categories.where((c) => c.type == _listingType).toList());
  }

  void _onListingTypeChanged(ListingType type) {
    setState(() {
      _listingType = type;
      _selectedCategory = null;
      _categories = [];
    });
    _loadCategories();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 5) return;
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _photos.add(File(file.path)));
  }

  Future<void> _publish() async {
    if (_selectedState == null) {
      AppMessenger.showError('Please select a state.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ProductService().createListing(
        type: listingTypeToString(_listingType),
        category: _selectedCategory?.slug ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        priceUnit: _priceUnitController.text.trim().isEmpty ? null : _priceUnitController.text.trim(),
        location: _locationController.text.trim(),
        state: _selectedState!,
        bedrooms: _listingType == ListingType.property ? int.tryParse(_bedroomsController.text) : null,
        bathrooms: _listingType == ListingType.property ? int.tryParse(_bathroomsController.text) : null,
        furnishing: _listingType == ListingType.property ? _furnishing : null,
        squareFeet: _listingType == ListingType.property ? int.tryParse(_sqftController.text) : null,
        listingMode: _listingType == ListingType.property ? _propertyMode : null,
        photos: _photos,
      );
      if (!mounted) return;
      AppMessenger.showSuccess('Your ad has been published successfully!');
      context.go('/vendor/dashboard');
    } catch (e) {
      if (!mounted) return;
      AppMessenger.showError('Could not publish your ad. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post an Ad', style: TextStyle(fontSize: 18)),
            Text('Step ${_step + 1} of 3', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(step: _step),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildStepBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      default:
        return _buildStep3();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('Listing Type', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _TypeChip(label: 'Product', selected: _listingType == ListingType.product, onTap: () => _onListingTypeChanged(ListingType.product))),
            const SizedBox(width: 8),
            Expanded(child: _TypeChip(label: 'Service', selected: _listingType == ListingType.service, onTap: () => _onListingTypeChanged(ListingType.service))),
            const SizedBox(width: 8),
            Expanded(
              child: _TypeChip(
                label: 'Property',
                icon: Icons.home_outlined,
                selected: _listingType == ListingType.property,
                onTap: () => _onListingTypeChanged(ListingType.property),
              ),
            ),
          ],
        ),
        if (_listingType == ListingType.property) ...[
          const SizedBox(height: 20),
          const Text('Property Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TypeChip(label: 'For Rent', selected: _propertyMode == 'rent', onTap: () => setState(() => _propertyMode = 'rent')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeChip(label: 'For Sale', selected: _propertyMode == 'sale', onTap: () => setState(() => _propertyMode = 'sale')),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Category>(
          value: _selectedCategory,
          hint: const Text('Choose a category'),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _selectedCategory != null ? () => setState(() => _step = 1) : null,
          child: const Text('Next: Photos'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Add up to 5 photos (first photo will be the cover)', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (int i = 0; i < _photos.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_photos[i], height: 100, width: 100, fit: BoxFit.cover),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.black54,
                        child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      icon: const CircleAvatar(radius: 10, backgroundColor: AppColors.danger, child: Icon(Icons.close, size: 12, color: Colors.white)),
                      onPressed: () => setState(() => _photos.removeAt(i)),
                    ),
                  ),
                ],
              ),
            if (_photos.length < 5)
              GestureDetector(
                onTap: _addPhoto,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_outlined, color: AppColors.textMuted),
                      SizedBox(height: 6),
                      Text('Add Photo', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 0), child: const Text('Back'))),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(onPressed: () => setState(() => _step = 2), child: const Text('Next: Details')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final isProperty = _listingType == ListingType.property;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isProperty ? 'Property Details' : 'Product Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: isProperty ? 'e.g., Modern 3 Bedroom Apartment in Lekki' : 'e.g., Premium Sharp Sand - 20 Ton Truck',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isProperty ? 'Describe the property features, amenities, and location...' : 'Describe your product or service in detail...',
          ),
        ),
        if (isProperty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bedrooms', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _bedroomsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '3')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bathrooms', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _bathroomsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '2')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Furnishing', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _furnishing,
            items: const ['Unfurnished', 'Semi-furnished', 'Fully furnished']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _furnishing = v ?? 'Unfurnished'),
          ),
          const SizedBox(height: 16),
          const Text('Square Feet', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _sqftController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '1800')),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price (₦)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '75000')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceUnitController,
                    decoration: InputDecoration(hintText: isProperty ? 'total price' : 'per truck'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: _locationController, decoration: const InputDecoration(hintText: 'e.g., Ikeja, Lagos')),
        const SizedBox(height: 16),
        const Text('State', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: const InputDecoration(hintText: 'Select a state'),
          items: NigeriaStates.all
              .where((s) => s != 'All Nigeria')
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedState = v),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back'))),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _publish,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Publish Ad'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget circle(int index) {
      final active = index <= step;
      return CircleAvatar(
        radius: 16,
        backgroundColor: active ? AppColors.primary : AppColors.border,
        child: Text('${index + 1}', style: TextStyle(color: active ? Colors.white : AppColors.textMuted)),
      );
    }

    Widget line(int index) {
      final active = index < step;
      return Expanded(child: Container(height: 3, color: active ? AppColors.primary : AppColors.border));
    }

    return Row(
      children: [
        circle(0),
        line(0),
        circle(1),
        line(1),
        circle(2),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
