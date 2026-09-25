import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_bloc.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_event.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_state.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:intl/intl.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TestHistoryBloc>().add(TestHistoryFetched());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TestHistoryBloc>().add(TestHistoryFetched());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  // Hàm tính toán màu sắc dựa trên tỉ lệ điểm (Phục vụ UI)
  Color _getScoreColor(int correct, int total) {
    if (total == 0) return Colors.grey;
    final double percent = correct / total;
    if (percent == 1.0) return Colors.blue.shade600; // Hoàn hảo
    if (percent >= 0.8) return Colors.green.shade600; // Giỏi
    if (percent >= 0.5) return Colors.orange.shade600; // Trung bình
    return Colors.red.shade500; // Yếu
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 241, 245),
      // Màu nền xám lạnh cực nhạt cho style hiện đại
      appBar: AppBar(
        title: const Text(
          'Lịch sử ôn tập',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<TestHistoryBloc, TestHistoryState>(
        builder: (context, state) {
          final bool isInitialLoading =
              (state.status == TestHistoryStatus.initial ||
                  state.status == TestHistoryStatus.loading) &&
              state.history.isEmpty;
          final bool isInitialError =
              state.status == TestHistoryStatus.failure &&
              state.history.isEmpty;

          return Column(
            children: [
              _buildUnifiedFilterPanel(
                context,
                state,
              ), // Đổi sang UI Filter mới
              Expanded(
                child: CommonRefresh(
                  controller: _scrollController,
                  onRefresh: () async {
                    context.read<TestHistoryBloc>().add(TestHistoryRefreshed());
                  },
                  slivers: [
                    if (isInitialLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (isInitialError)
                      SliverFillRemaining(
                        child: Center(
                          child: CommonFailure(
                            errorMessage: state.errorMessage ?? 'Có lỗi xảy ra',
                          ),
                        ),
                      )
                    else if (state.history.isEmpty)
                      const SliverFillRemaining(child: CommonEmpty())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        sliver: SliverList.builder(
                          itemCount: state.hasReachedMax
                              ? state.history.length
                              : state.history.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= state.history.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = state.history[index];

                            // Giữ nguyên logic Filter
                            if (state.searchQuery != null &&
                                state.searchQuery!.isNotEmpty) {
                              if (!item.testName.toLowerCase().contains(
                                state.searchQuery!.toLowerCase(),
                              )) {
                                return const SizedBox.shrink();
                              }
                            }

                            // Tính toán màu chủ đạo cho item này
                            final scoreColor = _getScoreColor(
                              item.correctAnswers,
                              item.totalQuestions,
                            );

                            // --- BẮT ĐẦU UI PHÁ CÁCH: TIMELINE + WATERMARK CARD ---
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 1. Trục thời gian (Timeline Axis)
                                  SizedBox(
                                    width: 56,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.completedAt != null
                                              ? DateFormat('HH:mm').format(
                                                  item.completedAt!.toLocal(),
                                                )
                                              : '--:--',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.completedAt != null
                                              ? DateFormat('dd/MM').format(
                                                  item.completedAt!.toLocal(),
                                                )
                                              : 'Đang làm',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.outline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // 2. Nội dung Card chính
                                  Expanded(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Thẻ nền
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: scoreColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              onTap: () {
                                                context.pushNamed(
                                                  AppRoute
                                                      .testHistoryDetail
                                                      .name,
                                                  pathParameters: {
                                                    'attemptId': item.id,
                                                  },
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: Stack(
                                                  children: [
                                                    // Cột viền màu thể hiện trạng thái (Indicator Bar)
                                                    Positioned(
                                                      left: 0,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        width: 6,
                                                        color: scoreColor,
                                                      ),
                                                    ),

                                                    // Điểm số Watermark in chìm siêu to khổng lồ
                                                    Positioned(
                                                      right: -10,
                                                      bottom: -15,
                                                      child: Text(
                                                        '${item.correctAnswers}/${item.totalQuestions}',
                                                        style: TextStyle(
                                                          fontSize: 72,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: scoreColor
                                                              .withValues(
                                                                alpha: 0.05,
                                                              ),
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),

                                                    // Nội dung thực tế của thẻ
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                            24,
                                                            16,
                                                            16,
                                                            16,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item
                                                                    .testName
                                                                    .isNotEmpty
                                                                ? item.testName
                                                                : 'Bài kiểm tra',
                                                            style: theme
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  letterSpacing:
                                                                      -0.3,
                                                                  height: 1.2,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),

                                                          // Hiển thị Điểm số dạng nổi bật
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .stars_rounded,
                                                                color:
                                                                    scoreColor,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                'Đạt ${item.correctAnswers} / ${item.totalQuestions} câu',
                                                                style: theme
                                                                    .textTheme
                                                                    .titleSmall
                                                                    ?.copyWith(
                                                                      color:
                                                                          scoreColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),

                                                          // Danh sách Tags
                                                          if (item
                                                              .questionTypes
                                                              .isNotEmpty) ...[
                                                            const SizedBox(
                                                              height: 16,
                                                            ),
                                                            Wrap(
                                                              spacing: 6,
                                                              runSpacing: 6,
                                                              children: item.questionTypes.map((
                                                                qt,
                                                              ) {
                                                                return Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .primary
                                                                        .withValues(
                                                                          alpha:
                                                                              0.5,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    _getQuestionTypeLabel(
                                                                      qt,
                                                                    ),
                                                                    style: theme
                                                                        .textTheme
                                                                        .labelSmall
                                                                        ?.copyWith(
                                                                          color: theme
                                                                              .colorScheme
                                                                              .onPrimary,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                            // --- KẾT THÚC UI PHÁ CÁCH ---
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnifiedFilterPanel(
    BuildContext context,
    TestHistoryState state,
  ) {
    final theme = Theme.of(context);
    final questionTypesMap = {
      '': 'Tất cả dạng câu hỏi',
      'multiple_choice': 'Trắc nghiệm',
      'true_false': 'Đúng/Sai',
      'fill_in_the_blank': 'Điền từ',
      'dictation': 'Chính tả',
      'matching': 'Ghép cặp',
      'flashcard': 'Flashcard',
    };

    final currentValue = state.selectedQuestionType ?? '';

    return Container(
      height: 56, // <--- CỐ ĐỊNH CHIỀU CAO TẠI ĐÂY (Giải quyết dứt điểm lỗi)
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // BỎ INTRINSIC HEIGHT ĐI
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ô Tìm kiếm (Search)
          Expanded(
            flex: 5,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                context.read<TestHistoryBloc>().add(
                  TestHistoryFilterChanged(search: val),
                );
              },
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Tìm bài ôn tập...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TestHistoryBloc>().add(
                            const TestHistoryFilterChanged(search: ''),
                          );
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),

          // Đường kẻ ngăn cách (Divider dọc)
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
            color: Colors.grey.shade200,
          ),

          // Dropdown Bộ lọc (Filter)
          Expanded(
            flex: 4,
            child: CustomDropdown<String>(
              isExpanded: true,
              hasBorder: false,
              backgroundColor: Colors.transparent,
              value: currentValue,
              items: questionTypesMap.keys.toList(),
              itemLabelBuilder: (val) =>
                  questionTypesMap[val] ?? 'Tất cả dạng câu hỏi',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              onChanged: (val) {
                final filterVal = val.isEmpty ? null : val;
                context.read<TestHistoryBloc>().add(
                  TestHistoryFilterChanged(questionTypes: filterVal),
                );
              },
            ),
          ),
        ],
      ),
    );
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
