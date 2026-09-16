import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/product_category.dart';
import '../../../presentation/providers/product_providers.dart';

/// Admin categories: name, image (shown on the customer home), display
/// order, optional parent (the store shows sub-categories under it) and the
/// active switch. Categories are never deleted — switch them off instead.
class AdminCategoryListScreen extends ConsumerWidget {
  const AdminCategoryListScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    List<ProductCategory> all, {
    ProductCategory? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryForm(all: all, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'قسم جديد',
        onPressed: () => _edit(context, categoriesAsync.value ?? const []),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الأقسام',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyView(
              message: 'لا توجد أقسام بعد',
              icon: Icons.category_outlined,
            );
          }
          final names = {for (final c in categories) c.id: c.name};
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = categories[i];
              final details = [
                if (c.parentId != null && names[c.parentId] != null)
                  'تابع لـ ${names[c.parentId]}',
                'الترتيب ${c.sortOrder}',
                if (!c.isActive) 'معطَّل',
              ].join(' • ');
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: c.imageUrl == null
                      ? null
                      : CachedNetworkImageProvider(c.imageUrl!),
                  child: c.imageUrl == null
                      ? const Icon(Icons.category_outlined)
                      : null,
                ),
                title: Text(c.name),
                subtitle: Text(details),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(context, categories, existing: c),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  final List<ProductCategory> all;
  final ProductCategory? existing;
  const _CategoryForm({required this.all, this.existing});

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _sort = TextEditingController(
    text: '${widget.existing?.sortOrder ?? 0}',
  );
  late String? _parentId = widget.existing?.parentId;
  late String? _imageUrl = widget.existing?.imageUrl;
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _uploading = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final url = await ref
          .read(productRepositoryProvider)
          .uploadCategoryImage(bytes, ext);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) setState(() => _error = AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final input = CategoryInput(
      id: widget.existing?.id,
      name: _name.text,
      parentId: _parentId,
      imageUrl: _imageUrl,
      sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
      isActive: _isActive,
    );
    final error = input.error;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(productRepositoryProvider).saveCategory(input);
      ref.invalidate(categoriesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppException.from(e).messageAr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = widget.existing?.id;
    // One level of nesting: a parent must itself be top-level, and a
    // category that already has children can't become someone's child.
    final hasChildren = widget.all.any((c) => c.parentId == selfId);
    final parents = widget.all
        .where((c) => c.id != selfId && c.parentId == null)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'قسم جديد' : 'تعديل القسم',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: _imageUrl == null
                      ? null
                      : CachedNetworkImageProvider(_imageUrl!),
                  child: _uploading
                      ? const CircularProgressIndicator()
                      : _imageUrl == null
                      ? const Icon(Icons.category_outlined, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _imageUrl == null ? 'إضافة صورة' : 'تغيير الصورة',
                  ),
                ),
                if (_imageUrl != null)
                  IconButton(
                    tooltip: 'إزالة الصورة',
                    onPressed: () => setState(() => _imageUrl = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: CategoryInput.maxNameLength,
              decoration: const InputDecoration(labelText: 'اسم القسم'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: parents.any((p) => p.id == _parentId)
                  ? _parentId
                  : null,
              decoration: InputDecoration(
                labelText: 'تابع لقسم',
                helperText: hasChildren
                    ? 'هذا القسم له أقسام فرعية، فلا يمكن جعله فرعيًا'
                    : null,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('قسم رئيسي')),
                for (final p in parents)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: hasChildren
                  ? null
                  : (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sort,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'الترتيب',
                helperText: 'الأصغر يظهر أولًا',
              ),
            ),
            if (widget.existing != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ظاهر للعملاء'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving || _uploading ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
