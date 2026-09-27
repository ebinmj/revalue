import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/app_page.dart';
import 'diagnostic_chat_screen.dart';

class ReduceScanScreen extends StatefulWidget {
  const ReduceScanScreen({
    this.initialFocusDescription = false,
    super.key,
  });

  final bool initialFocusDescription;

  @override
  State<ReduceScanScreen> createState() => _ReduceScanScreenState();
}

class _ReduceScanScreenState extends State<ReduceScanScreen> {
  final _descriptionController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _imageError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    if (widget.initialFocusDescription) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _descriptionFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
        _imageError = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the selected image.')),
      );
    }
  }

  void _startDiagnostic() {
    final description = _descriptionController.text.trim();

    setState(() {
      _imageError =
          _selectedImage == null ? 'Please add a photo of the item.' : null;
      _descriptionError =
          description.isEmpty ? 'Tell us what is wrong with the item.' : null;
    });

    if (_selectedImage == null || description.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiagnosticChatScreen(
          imageBytes: _selectedImageBytes!,
          initialDescription: description,
          mode: 'reduce',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reduce · Repair Scan')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Text(
              'Analyze for Repair',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share a photo and describe the problem. The AI will ask follow-up questions then give you a repair evaluation.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI will identify the item and ask targeted questions before giving a repair assessment.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ImagePreview(
                      bytes: _selectedImageBytes,
                      onTap: _showImageSourcePicker,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showImageSourcePicker,
                          icon: const Icon(Icons.upload_outlined),
                          label: const Text('Upload Photo'),
                        ),
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Take Photo'),
                        ),
                      ],
                    ),
                    if (_imageError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _imageError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What is wrong with the item?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              minLines: 4,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Laptop doesn\'t turn on. Screen still works.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_descriptionError != null) ...[
              const SizedBox(height: 8),
              Text(
                _descriptionError!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startDiagnostic,
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text('Start Repair Diagnostic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes, required this.onTap});

  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child:
              bytes == null
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add item photo',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Image.memory(bytes!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
