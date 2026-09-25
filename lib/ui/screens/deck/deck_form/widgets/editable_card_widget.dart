import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/services/media_service.dart';
import 'package:mind_deck/data/repositories/image_repository.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/ui/commons/image_screens/common_image_viewer.dart';
import 'package:mind_deck/core/failures.dart';

class EditableCardWidget extends StatefulWidget {
  final int index;
  final FlashcardModel card;
  final VoidCallback onDelete;
  final Function(String front, String back, String? imageUrl) onChanged;

  const EditableCardWidget({
    super.key,
    required this.index,
    required this.card,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<EditableCardWidget> createState() => _EditableCardWidgetState();
}

class _EditableCardWidgetState extends State<EditableCardWidget> {
  late TextEditingController _frontController;
  late TextEditingController _backController;
  bool _isUploading = false;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card.frontText);
    _backController = TextEditingController(text: widget.card.backText);

    _frontController.addListener(_onFieldsChanged);
    _backController.addListener(_onFieldsChanged);
  }

  @override
  void didUpdateWidget(covariant EditableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _frontController.text = widget.card.frontText;
      _backController.text = widget.card.backText;
      _localImagePath = null;
    }
  }

  @override
  void dispose() {
    _frontController.removeListener(_onFieldsChanged);
    _backController.removeListener(_onFieldsChanged);
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    widget.onChanged(_frontController.text, _backController.text, widget.card.frontImageUrl);
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final File? image = await DI().sl<MediaService>().pickImage();
      if (image != null) {
        setState(() {
          _localImagePath = image.path;
        });

        final response = await DI().sl<ImageRepository>().uploadImage(image);
        if (response.success && response.data != null) {
          final data = response.data!;
          final rawPath = data['url'] ?? data['path'] ?? data['imageUrl'] ?? '';
          String finalUrl = rawPath;

          if (finalUrl.isNotEmpty && !finalUrl.startsWith('http')) {
            finalUrl = '${ApiEndpoints.url}$finalUrl';
          }

          widget.onChanged(_frontController.text, _backController.text, finalUrl);
        } else {
          if (mounted) {
            CustomToast.show(context, CustomToast.danger(message: 'Không thể upload hình ảnh'));
          }
        }
      }
    } on Failure catch (e) {
      if (mounted) CustomToast.show(context, CustomToast.danger(message: e.message));
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, CustomToast.danger(message: 'Lỗi chọn ảnh: $e'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _deleteImage() {
    setState(() {
      _localImagePath = null;
    });
    widget.onChanged(_frontController.text, _backController.text, null);
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    final hasLocal = _localImagePath != null;
    final hasRemote = widget.card.frontImageUrl != null && widget.card.frontImageUrl!.isNotEmpty;

    if (!hasLocal && !hasRemote) {
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: colorScheme.primary, size: 24),
              const SizedBox(height: 4),
              Text(
                'Thêm ảnh',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget imageWidget;
    if (hasLocal) {
      imageWidget = Image.file(File(_localImagePath!), fit: BoxFit.cover, width: 80, height: 80);
    } else {
      imageWidget = Image.network(
        widget.card.frontImageUrl!,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 32),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            print("ấn");
            final imgPath = hasLocal ? 'file://${_localImagePath!}' : widget.card.frontImageUrl!;
            CommonImageViewer.show(context, images: [imgPath], initialIndex: 0);
          },
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: imageWidget),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: _deleteImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Title and Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thẻ #${widget.index}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Fields Column
              Expanded(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _frontController,
                      label: 'Mặt trước (Thuật ngữ)',
                      hintText: 'Nhập thuật ngữ hoặc câu hỏi...',
                      isRequired: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mặt trước không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _backController,
                      label: 'Mặt sau (Định nghĩa)',
                      hintText: 'Nhập định nghĩa hoặc câu trả lời...',
                      isRequired: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mặt sau không được để trống';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Right Image Slot
              Column(
                children: [
                  const SizedBox(height: 24), // Align with first text field
                  if (_isUploading)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    _buildImagePreview(colorScheme),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
