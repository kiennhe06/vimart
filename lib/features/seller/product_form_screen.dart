import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/design.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_busy.dart';
import '../../widgets/app_feedback.dart';
import '../../core/providers.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../widgets/async_view.dart';
import '../../widgets/network_image_box.dart';
import '../catalog/catalog_providers.dart';
import 'seller_repository.dart';

/// Form thêm mới / chỉnh sửa sản phẩm (kèm các phân loại giá + tồn kho).
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  /// null = tạo mới, có id = chỉnh sửa.
  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  int? _categoryId;
  final List<_VariantControllers> _variants = [];
  bool _saving = false;
  bool _prefilled = false;
  bool _uploadingImage = false;

  bool get _isEdit => widget.productId != null;

  /// Chọn ảnh từ thư viện rồi upload lên server, lấy URL gán vào ô link ảnh.
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return; // người dùng hủy chọn

    setState(() => _uploadingImage = true);
    try {
      final url = await ref.read(apiClientProvider).uploadImage(picked.path);
      setState(() => _imageUrl.text = url);
      if (mounted) {
        showAppSnack(context, ref.read(stringsProvider).imageUploaded, type: AppSnackType.success);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_isEdit) _variants.add(_VariantControllers());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  /// Điền sẵn dữ liệu khi chỉnh sửa (chạy 1 lần khi tải xong chi tiết).
  void _prefill(ProductDetail product) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = product.name;
    _description.text = product.description ?? '';
    _imageUrl.text = product.imageUrl ?? '';
    for (final v in product.variants) {
      _variants.add(_VariantControllers(nameText: v.name, priceValue: v.price, stockValue: v.stock));
    }
    if (_variants.isEmpty) _variants.add(_VariantControllers());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final variants = _variants
        .map((v) => VariantInput(
              name: v.name.text.trim().isEmpty ? 'Mặc định' : v.name.text.trim(),
              price: int.tryParse(v.price.text.trim()) ?? 0,
              stock: int.tryParse(v.stock.text.trim()) ?? 0,
            ))
        .toList();

    setState(() => _saving = true);
    try {
      final repo = ref.read(sellerRepositoryProvider);
      if (_isEdit) {
        await repo.updateProduct(
          id: widget.productId!,
          name: _name.text.trim(),
          description: _description.text.trim(),
          categoryId: _categoryId,
          imageUrl: _imageUrl.text.trim(),
          variants: variants,
        );
      } else {
        await repo.createProduct(
          name: _name.text.trim(),
          description: _description.text.trim(),
          categoryId: _categoryId,
          imageUrl: _imageUrl.text.trim(),
          variants: variants,
        );
      }
      ref.invalidate(myProductsProvider);
      if (widget.productId != null) ref.invalidate(productDetailProvider(widget.productId!));
      if (mounted) {
        showAppSnack(context, ref.read(stringsProvider).productSaved, type: AppSnackType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final s = ref.watch(stringsProvider);

    // Khi chỉnh sửa: chờ tải chi tiết để prefill.
    if (_isEdit && !_prefilled) {
      final detailAsync = ref.watch(productDetailProvider(widget.productId!));
      return Scaffold(
        appBar: AppBar(title: Text(s.editProduct)),
        body: AsyncView(
          value: detailAsync,
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId!)),
          data: (product) {
            _prefill(product);
            return _buildForm(categoriesAsync);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? s.editProduct : s.addProduct)),
      body: _buildForm(categoriesAsync),
    );
  }

  Widget _buildForm(AsyncValue<List<Category>> categoriesAsync) {
    final s = ref.watch(stringsProvider);
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: s.productName),
                  validator: (v) => (v == null || v.trim().length < 2) ? s.enterProductName : null,
                ),
                const SizedBox(height: 12),
                categoriesAsync.maybeWhen(
                  data: (cats) => DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(labelText: s.category),
                    items: cats
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                Text(s.productImage, style: TextStyle(fontSize: 13, color: context.c.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Xem trước ảnh (tự cập nhật khi link đổi)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: ValueListenableBuilder(
                          valueListenable: _imageUrl,
                          builder: (_, value, _) => NetworkImageBox(url: value.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _uploadingImage ? null : _pickAndUploadImage,
                            icon: _uploadingImage
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.image_outlined, color: AppColors.brand),
                            label: Text(_uploadingImage ? s.uploadingImage : s.pickImage),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _imageUrl,
                            decoration: InputDecoration(
                              labelText: s.orPasteImageLink,
                              hintText: 'https://...',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: s.description),
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Text(s.variantsSection,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _variants.add(_VariantControllers())),
                      icon: const Icon(Icons.add),
                      label: Text(s.addShort),
                    ),
                  ],
                ),
                // Thêm/bớt phân loại -> chiều cao co giãn mượt thay vì nhảy.
                AnimatedSize(
                  duration: AppMotion.dur(context, AppMotion.base),
                  curve: AppMotion.emphasized,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      for (int i = 0; i < _variants.length; i++) _variantRow(i),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: BusySwitch(busy: _saving, child: Text(s.saveProduct)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _variantRow(int index) {
    final v = _variants[index];
    final s = ref.watch(stringsProvider);
    return Padding(
      key: ObjectKey(v),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: v.name,
              decoration: InputDecoration(labelText: s.variantNameHint),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: v.price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.price),
              validator: (val) => (int.tryParse(val ?? '') == null) ? s.mustBeNumber : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: v.stock,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.stock),
              validator: (val) => (int.tryParse(val ?? '') == null) ? s.mustBeNumber : null,
            ),
          ),
          if (_variants.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() {
                _variants.removeAt(index).dispose();
              }),
            ),
        ],
      ),
    );
  }
}

/// Nhóm controller cho 1 dòng phân loại.
class _VariantControllers {
  _VariantControllers({String nameText = '', int? priceValue, int? stockValue})
      : name = TextEditingController(text: nameText),
        price = TextEditingController(text: priceValue?.toString() ?? ''),
        stock = TextEditingController(text: stockValue?.toString() ?? '');

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController stock;

  void dispose() {
    name.dispose();
    price.dispose();
    stock.dispose();
  }
}
