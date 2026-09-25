import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/report_model.dart';
import 'package:mind_deck/services/media_service.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'bloc/report_form_bloc.dart';
import 'bloc/report_form_event.dart';
import 'bloc/report_form_state.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  ReportType _selectedType = ReportType.bugUi;
  ReportTargetType _selectedTargetType = ReportTargetType.system;
  final String? _targetId = null;

  final List<File> _selectedImages = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final mediaService = DI().sl<MediaService>();
    final images = await mediaService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (_selectedImages.length < 3) {
            _selectedImages.add(img);
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitReport() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<ReportFormBloc>().add(
      ReportFormSubmitted(
        type: _selectedType,
        targetType: _selectedTargetType,
        targetId: _targetId,
        description: _descriptionController.text.trim(),
        images: _selectedImages,
      ),
    );
  }

  String _getTypeText(ReportType type) {
    switch (type) {
      case ReportType.contentViolation:
        return 'Vi phạm nội dung';
      case ReportType.bugUi:
        return 'Lỗi giao diện / chức năng';
      case ReportType.paymentIssue:
        return 'Vấn đề thanh toán';
      case ReportType.accountSupport:
        return 'Hỗ trợ tài khoản';
      case ReportType.other:
        return 'Khác';
    }
  }

  String _getTargetTypeText(ReportTargetType type) {
    switch (type) {
      case ReportTargetType.deck:
        return 'Bộ thẻ';
      case ReportTargetType.folder:
        return 'Thư mục';
      case ReportTargetType.user:
        return 'Người dùng';
      case ReportTargetType.classroom:
        return 'Lớp học';
      case ReportTargetType.system:
        return 'Hệ thống';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<ReportFormBloc, ReportFormState>(
      listener: (context, state) {
        if (state.status == ReportFormStatus.success) {
          CustomToast.show(
            context,
            CustomToast.success(message: state.successMessage ?? 'Thành công!'),
          );
          context.pop(true);
        } else if (state.status == ReportFormStatus.failure) {
          CustomToast.show(
            context,
            CustomToast.danger(message: state.errorMessage ?? 'Có lỗi xảy ra'),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: const Text('Gửi phản ánh mới'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vấn đề bạn gặp phải là gì?',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    CustomDropdown<ReportType>(
                      value: _selectedType,
                      items: ReportType.values,
                      itemLabelBuilder: _getTypeText,
                      isExpanded: true,
                      onChanged: (val) {
                        setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Phạm vi lỗi',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    CustomDropdown<ReportTargetType>(
                      value: _selectedTargetType,
                      items: ReportTargetType.values,
                      itemLabelBuilder: _getTargetTypeText,
                      isExpanded: true,
                      onChanged: (val) {
                        setState(() => _selectedTargetType = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Mô tả chi tiết',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: 'Mô tả lỗi hoặc vấn đề bạn gặp phải...',
                      maxLines: 5,
                      isRequired: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập mô tả chi tiết';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Ảnh đính kèm (Tùy chọn)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._selectedImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        if (_selectedImages.length < 3)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: colorScheme.primary,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: BlocBuilder<ReportFormBloc, ReportFormState>(
                  builder: (context, state) {
                    final isLoading = state.status == ReportFormStatus.loading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Gửi báo cáo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
