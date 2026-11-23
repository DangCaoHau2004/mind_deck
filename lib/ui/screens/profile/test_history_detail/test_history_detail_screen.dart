import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_bloc.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_event.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_state.dart';
import 'package:mind_deck/data/models/test_attempt_detail_model.dart';
import 'package:intl/intl.dart';

class TestHistoryDetailScreen extends StatefulWidget {
  final String attemptId;
  const TestHistoryDetailScreen({super.key, required this.attemptId});

  @override
  State<TestHistoryDetailScreen> createState() => _TestHistoryDetailScreenState();
}

class _TestHistoryDetailScreenState extends State<TestHistoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TestHistoryDetailBloc>().add(TestHistoryDetailFetched(widget.attemptId));
  }

  // Helper tính màu điểm số đồng bộ với màn hình trước
  Color _getScoreColor(double percentage) {
    if (percentage == 100) return Colors.blue.shade600;
    if (percentage >= 80) return Colors.green.shade600;
    if (percentage >= 50) return Colors.orange.shade600;
    return Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 241, 245),
      appBar: AppBar(
        title: const Text(
          'Chi tiết kết quả',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<TestHistoryDetailBloc, TestHistoryDetailState>(
        builder: (context, state) {
          if (state.status == TestHistoryDetailStatus.initial ||
              state.status == TestHistoryDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TestHistoryDetailStatus.failure) {
            return CommonRefresh(
              onRefresh: () async {
                context.read<TestHistoryDetailBloc>().add(
                  TestHistoryDetailFetched(widget.attemptId),
                );
              },
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: CommonFailure(errorMessage: state.errorMessage ?? 'Có lỗi xảy ra'),
                  ),
                ),
              ],
            );
          }

          final detail = state.detail;
          if (detail == null) {
            return const Center(child: CommonEmpty());
          }

          return CommonRefresh(
            onRefresh: () async {
              context.read<TestHistoryDetailBloc>().add(TestHistoryDetailFetched(widget.attemptId));
            },
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildOverviewCard(context, detail),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chi tiết từng câu hỏi',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverList.builder(
                  itemCount: detail.answers.length,
                  itemBuilder: (context, index) {
                    final answer = detail.answers[index];
                    return _buildAnswerCard(context, answer, index + 1);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================
  // 1. GIAO DIỆN TỔNG QUAN (DASHBOARD STYLE)
  // =========================================
  Widget _buildOverviewCard(BuildContext context, TestAttemptDetailModel detail) {
    final theme = Theme.of(context);
    // Đề tắt xem điểm (`visibility.showScore = false`): không hiện điểm / số câu đúng.
    final scoreColor = detail.showScore
        ? _getScoreColor(detail.scorePercentage.toDouble())
        : Colors.blueGrey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng 1: Tiêu đề & Tên bài test
            Text(
              'BÀI KIỂM TRA',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.testName.isNotEmpty ? detail.testName : 'Không có tiêu đề',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // Dòng 2: Khu vực hiển thị điểm số (To, phá cách)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  detail.showScore ? detail.scorePercentage.toStringAsFixed(0) : '--',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: scoreColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const Spacer(),
                // Thông tin phụ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMiniBadge(
                      context,
                      Icons.check_circle_rounded,
                      detail.showScore
                          ? 'Đúng: ${detail.correctAnswers}/${detail.totalQuestions}'
                          : 'Điểm do giảng viên công bố',
                      Colors.green.shade600,
                    ),
                    const SizedBox(height: 8),
                    if (detail.completedAt != null)
                      _buildMiniBadge(
                        context,
                        Icons.calendar_month_rounded,
                        DateFormat('HH:mm - dd/MM/yy').format(detail.completedAt!.toLocal()),
                        theme.colorScheme.primary,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // =========================================
  // 2. GIAO DIỆN CÂU HỎI (VIỀN FULL + WATERMARK)
  // =========================================
  Widget _buildAnswerCard(BuildContext context, TestAttemptAnswerModel answer, int index) {
    final theme = Theme.of(context);
    final bool isCorrect = answer.isCorrect;
    // Đề tắt xem đáp án: BE ẩn đúng/sai (isCorrect = null) -> KHÔNG coi câu là sai.
    final bool known = answer.isCorrectKnown;
    final Color statusColor = !known
        ? Colors.blueGrey.shade500
        : (isCorrect ? Colors.green.shade600 : Colors.red.shade600);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: !known
            ? Colors.blueGrey.shade50.withValues(alpha: 0.3)
            : (isCorrect
                  ? Colors.green.shade50.withValues(alpha: 0.3)
                  : Colors.red.shade50.withValues(alpha: 0.3)), // Nền ám nhẹ màu trạng thái
        borderRadius: BorderRadius.circular(20),
        // SỬ DỤNG VIỀN BAO QUANH TOÀN BỘ THẺ THEO YÊU CẦU
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 2.0, // Độ dày của viền
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark số thứ tự khổng lồ in chìm
          Positioned(
            right: -10,
            top: -20,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                color: statusColor.withValues(alpha: 0.05), // In chìm
                fontStyle: FontStyle.italic,
                letterSpacing: -5,
              ),
            ),
          ),

          // Nội dung chính
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Type & Icon)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getQuestionTypeLabel(answer.questionType),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !known
                                ? Icons.task_alt_rounded
                                : (isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded),
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            !known ? 'ĐÃ NỘP' : (isCorrect ? 'ĐÚNG' : 'SAI'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nội dung Flashcard
                if (answer.flashcardInfo != null) ...[
                  _buildContentBlock(
                    context: context,
                    label: 'Câu hỏi',
                    content: answer.flashcardInfo!.frontText,
                  ),
                  const SizedBox(height: 16),
                  _buildContentBlock(
                    context: context,
                    label: 'Đáp án chuẩn',
                    content: answer.flashcardInfo!.backText,
                    contentColor: Colors.green.shade700,
                    bgColor: Colors.green.shade50,
                  ),
                ],

                // Câu trả lời của user
                if (answer.userAnswerDetails.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  _buildContentBlock(
                    context: context,
                    label: 'Câu trả lời của bạn',
                    content: _formatUserAnswer(answer),
                    contentColor: statusColor,
                    bgColor: !known
                        ? Colors.blueGrey.withValues(alpha: 0.1)
                        : (isCorrect
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1)),
                    icon: !known
                        ? Icons.remove_rounded
                        : (isCorrect ? Icons.check_rounded : Icons.close_rounded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Khối block để phân cấp UI rõ ràng hơn (Label nhỏ + Content nền nổi bật)
  Widget _buildContentBlock({
    required BuildContext context,
    required String label,
    required String content,
    Color? contentColor,
    Color? bgColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: contentColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: contentColor ?? theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatUserAnswer(TestAttemptAnswerModel answer) {
    if (answer.userAnswerDetails.isEmpty) return 'Không có câu trả lời';

    if (answer.questionType == 'flashcard') {
      final isRemembered = answer.userAnswerDetails['isRemembered'] == true;
      return isRemembered ? 'Đã nhớ' : 'Chưa nhớ';
    }

    if (answer.userAnswerDetails.containsKey('userAnswer')) {
      final userAnswer = answer.userAnswerDetails['userAnswer'];
      if (answer.questionType == 'true_false') {
        return userAnswer.toString() == 'true' ? 'Đúng' : 'Sai';
      }
      return userAnswer.toString();
    }

    return answer.userAnswerDetails.toString();
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Trắc nghiệm';
      case 'true_false':
        return 'Đúng/Sai';
      case 'fill_in_the_blank':
        return 'Điền từ';
      case 'dictation':
        return 'Chính tả';
      case 'matching':
        return 'Ghép cặp';
      case 'flashcard':
        return 'Flashcard';
      default:
        return type;
    }
  }
}
