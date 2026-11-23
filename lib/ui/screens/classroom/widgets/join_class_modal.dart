import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_event.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_state.dart';

class JoinClassModal extends StatefulWidget {
  final String? initialCode;
  const JoinClassModal({super.key, this.initialCode});

  @override
  State<JoinClassModal> createState() => _JoinClassModalState();
}

class _JoinClassModalState extends State<JoinClassModal> {
  final _joinCodeController = TextEditingController();
  bool _isLoadingPreview = false;
  ClassModel? _previewClass;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _joinCodeController.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPreview(widget.initialCode!);
      });
    }
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview(String code) async {
    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });

    try {
      final repo = DI().sl<ClassRepository>();
      final response = await repo.previewClass(code);
      if (response.success && response.data != null) {
        setState(() {
          _previewClass = response.data;
          _isLoadingPreview = false;
        });
      } else {
        setState(() {
          _previewError = response.message ?? 'Không tìm thấy lớp học';
          _isLoadingPreview = false;
        });
      }
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _previewError = ClassErrorMessages.of(f);
        _isLoadingPreview = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: _previewClass == null ? 0.48 : 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 14,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo chỉ thị đầu ô bottom sheet
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 26),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  _previewClass == null ? "Tìm lớp học" : "Thông tin lớp học",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 28),

                if (_previewClass == null) ...[
                  // Khung nhập code
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
                    ),
                    child: TextField(
                      controller: _joinCodeController,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        hintText: "Nhập mã lớp (VÍ DỤ: TOEIC750)",
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 22),
                      ),
                    ),
                  ),
                  if (_previewError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            color: colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _previewError!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoadingPreview ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text(
                            "Hủy",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoadingPreview
                              ? null
                              : () {
                                  final code = _joinCodeController.text.trim();
                                  if (code.isNotEmpty) {
                                    _fetchPreview(code);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _isLoadingPreview
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Tìm kiếm",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Vùng hiển thị xem trước thông tin lớp học tìm kiếm được
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _previewClass!.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "Giáo viên: ${_previewClass!.ownerName ?? _previewClass!.owner?.fullName ?? 'N/A'}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_2_fill,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${_previewClass!.memberCount} thành viên",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (_previewClass!.description != null &&
                      _previewClass!.description!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      _previewClass!.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Toàn bộ khối điều khiển xử lý Logic Bloc nút bấm
                  BlocConsumer<ClassListBloc, ClassListState>(
                    listenWhen: (previous, current) =>
                        previous.isProcessing != current.isProcessing,
                    listener: (context, state) {
                      if (!state.isProcessing) {
                        if (state.processSuccess) {
                          Navigator.pop(context);
                          final result = state.joinResult;
                          if (result == null) {
                            // Từ chối lời mời: không có kết quả tham gia.
                            CustomToast.show(
                              context,
                              CustomToast.success(message: 'Đã từ chối lời mời'),
                            );
                          } else if (result.isPending) {
                            // BE trả `pending` khi lớp bật duyệt (kể cả sau khi chấp nhận lời mời).
                            CustomToast.show(
                              context,
                              CustomToast.success(
                                message: 'Đã gửi yêu cầu tham gia! Vui lòng chờ duyệt.',
                              ),
                            );
                          } else {
                            CustomToast.show(
                              context,
                              CustomToast.success(message: 'Đã tham gia lớp học!'),
                            );
                            // Không truyền `extra`: dữ liệu xem trước chưa phải của thành viên,
                            // để màn lớp tự tải lại đầy đủ (settings, permissions...).
                            context.pushNamed(
                              AppRoute.classroomDetail.name,
                              pathParameters: {'id': _previewClass!.id},
                            );
                          }
                        } else if (state.processErrorMessage != null) {
                          CustomToast.show(
                            context,
                            CustomToast.danger(message: state.processErrorMessage!),
                          );
                        }
                      }
                    },
                    builder: (context, state) {
                      final myStatus = _previewClass!.myStatus;
                      final myRole = _previewClass!.myRole;
                      final isOwner = _previewClass!.isOwner;

                      Widget ctaButton;

                      if (myStatus == 'approved' || myRole == 'owner' || isOwner) {
                        ctaButton = ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.pushNamed(
                              AppRoute.classroomDetail.name,
                              pathParameters: {'id': _previewClass!.id},
                              extra: _previewClass!.toJson(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          child: Text(
                            "Vào lớp",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      } else if (myStatus == 'invited') {
                        // Đã được mời: Chấp nhận / Từ chối thay cho "Xin tham gia".
                        ctaButton = Column(
                          children: [
                            Text(
                              'Bạn được mời tham gia lớp học này',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: state.isProcessing
                                        ? null
                                        : () => context.read<ClassListBloc>().add(
                                            ClassInvitationResponded(
                                              classId: _previewClass!.id,
                                              accept: false,
                                            ),
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 60),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Từ chối'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: state.isProcessing
                                        ? null
                                        : () => context.read<ClassListBloc>().add(
                                            ClassInvitationResponded(
                                              classId: _previewClass!.id,
                                              accept: true,
                                            ),
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      elevation: 0,
                                      minimumSize: const Size(0, 60),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: state.isProcessing
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : Text(
                                            'Chấp nhận',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else if (myStatus == 'pending') {
                        ctaButton = ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          child: Text(
                            "Đang chờ duyệt",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      } else {
                        ctaButton = Column(
                          children: [
                            ElevatedButton(
                              onPressed: state.isProcessing
                                  ? null
                                  : () {
                                      context.read<ClassListBloc>().add(
                                        // Chỉ gửi mã lớp (BE nhận `joinCode` HOẶC `classId`).
                                        ClassJoined(joinCode: _joinCodeController.text.trim()),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(double.infinity, 60),
                              ),
                              child: state.isProcessing
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      "Xin tham gia",
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                            if (_previewClass!.requireApproval)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  "Cần sự phê duyệt của giáo viên",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          ctaButton,
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _previewClass = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              textStyle: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text("Tìm lớp khác"),
                          ),
                        ],
                      );
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
}
