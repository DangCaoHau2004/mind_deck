import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_recommended_card.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_trending_list_item.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_classroom_card.dart';
import 'bloc/discover_bloc.dart';
import 'bloc/discover_event.dart';
import 'bloc/discover_state.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchType = 'all';

  @override
  void initState() {
    super.initState();
    context.read<DiscoverBloc>().add(DiscoverLoaded());

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmit() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<DiscoverBloc>().add(DiscoverSearched(query, type: _searchType));
      _searchFocusNode.unfocus();
    }
  }

  Color _hexToColor(String? code) {
    if (code == null || code.isEmpty) return Colors.grey;
    if (code.startsWith('#')) {
      code = code.substring(1);
    }
    if (code.length == 6) {
      code = 'FF$code';
    }
    try {
      return Color(int.parse(code, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 40 / 255),
                    colorScheme.surfaceContainer,
                    colorScheme.secondaryContainer.withValues(alpha: 25 / 255),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeaderAndSearch(colorScheme, textTheme),
                Expanded(
                  child: BlocBuilder<DiscoverBloc, DiscoverState>(
                    builder: (context, state) {
                      if (_isSearching) {
                        return _buildSearchView(state, colorScheme, textTheme);
                      } else {
                        return _buildDiscoverView(state, colorScheme, textTheme);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndSearch(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isSearching) ...[
            Text('Khám phá', style: textTheme.displaySmall?.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearchSubmit(),
                  decoration: InputDecoration(
                    hintText: 'Tìm bộ thẻ, thư mục, tag...',
                    hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
                      onPressed: _onSearchSubmit,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface.withValues(alpha: 220 / 255),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: TextButton(
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      _searchController.clear();
                      context.read<DiscoverBloc>().add(DiscoverSearched(''));
                      setState(() {
                        _isSearching = false;
                        _searchType = 'all'; // reset type
                      });
                    },
                    child: Text(
                      'Hủy',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
                    ),
                  ),
                ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all', colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bộ thẻ', 'deck', colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Thư mục', 'folder', colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chủ đề', 'tag', colorScheme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _searchType == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _searchType = value;
          });
          _onSearchSubmit(); // Tự động search lại với type mới
        }
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
      ),
    );
  }

  Widget _buildSearchView(DiscoverState state, ColorScheme colorScheme, TextTheme textTheme) {
    if (state.searchStatus == SearchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchStatus == SearchStatus.failure) {
      return CommonFailure(errorMessage: state.searchErrorMessage ?? 'Lỗi tìm kiếm');
    }

    if (state.searchStatus == SearchStatus.success) {
      if (state.searchResults.isNotEmpty) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.searchResults.length,
          itemBuilder: (context, index) {
            final item = state.searchResults[index];
            final type = item.type;

            final name = item.data['name'] ?? item.searchContent;
            final colorHex = item.data['color'] ?? '#673AB7';
            final themeColor = ColorUtils.parseHex(colorHex);

            Widget leadingIcon;
            String subtitleText;

            if (type == SearchType.tag) {
              leadingIcon = Icon(Icons.tag_rounded, color: themeColor);
              subtitleText = 'Chủ đề';
            } else if (type == SearchType.folder) {
              final iconKey = item.data['icon'] ?? 'default_folder';
              leadingIcon = Icon(AppIcons.getIconFromKey(iconKey), color: themeColor);
              subtitleText = item.data['description'] ?? 'Thư mục';
            } else {
              // deck
              leadingIcon = Icon(Icons.style_rounded, color: themeColor);
              subtitleText = item.data['description'] ?? 'Bộ thẻ';
            }

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: leadingIcon,
              ),
              title: Text(name),
              subtitle: Text(subtitleText, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                if (type == SearchType.tag) {
                  setState(() {
                    _searchType = 'tag';
                  });
                  _searchController.text = name;
                  _onSearchSubmit();
                } else if (type == SearchType.folder) {
                  context.pushNamed(
                    AppRoute.folderDetail.name,
                    pathParameters: {'id': item.data['id'] ?? item.id},
                  );
                } else {
                  context.pushNamed(
                    AppRoute.deckDetail.name,
                    pathParameters: {'id': item.data['id'] ?? item.id},
                  );
                }
              },
            );
          },
        );
      } else {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [Padding(padding: const EdgeInsets.only(top: 24), child: CommonEmpty.search())],
        );
      }
    }

    final trendingKeywords = state.discoveryData?.trendingKeywords ?? [];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded, color: colorScheme.error, size: 22),
            const SizedBox(width: 8),
            Text(
              'Xu hướng tìm kiếm',
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10.0,
          runSpacing: 12.0,
          children: trendingKeywords.map((keyword) {
            return ActionChip(
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 30 / 255)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    keyword,
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
                  ),
                ],
              ),
              onPressed: () {
                setState(() {
                  _searchType = 'all'; // Có thể set mặc định là all khi bấm trending
                  _isSearching = true;
                });
                _searchController.text = keyword;
                _onSearchSubmit();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscoverView(DiscoverState state, ColorScheme colorScheme, TextTheme textTheme) {
    if (state.status == DiscoverStatus.loading && state.discoveryData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == DiscoverStatus.failure && state.discoveryData == null) {
      return CommonFailure(errorMessage: state.errorMessage ?? 'Có lỗi xảy ra');
    }

    final data = state.discoveryData;
    if (data == null) {
      return const CommonEmpty(title: 'Trống', subtitle: 'Chưa có dữ liệu khám phá.');
    }

    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<DiscoverBloc>();
        bloc.add(DiscoverRefreshed());
        await bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // --- 1. CHỦ ĐỀ ĐƯỢC QUAN TÂM (Tags) ---
            if (data.popularTopics.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                child: Text(
                  'Chủ đề được quan tâm',
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: data.popularTopics.length,
                  itemBuilder: (context, index) {
                    final tag = data.popularTopics[index];
                    final tagColor = _hexToColor(tag.color);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ActionChip(
                        backgroundColor: tagColor.withValues(alpha: 30 / 255),
                        side: BorderSide(color: tagColor.withValues(alpha: 80 / 255)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        avatar: Icon(Icons.tag_rounded, size: 16, color: tagColor),
                        label: Text(
                          tag.name,
                          style: textTheme.labelMedium?.copyWith(color: tagColor),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchType = 'tag'; // Bấm vào tag thì type = tag
                            _isSearching = true;
                          });
                          _searchController.text = tag.name;
                          _onSearchSubmit();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            // --- 2. DÀNH CHO BẠN (Gợi ý cá nhân) ---
            if (data.personalizedDecks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: Text(
                  'Gợi ý dành riêng cho bạn',
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: data.personalizedDecks.length,
                  itemBuilder: (context, index) {
                    return DiscoverRecommendedCard(item: data.personalizedDecks[index]);
                  },
                ),
              ),
            ],

            // --- 3. NỘI DUNG THỊNH HÀNH ---
            if (data.suggestedContents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Nội dung thịnh hành',
                      style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                    ),
                    // GestureDetector(
                    //   onTap: () {
                    //     context.pushNamed(AppRoute.discoverPopular.name);
                    //   },
                    //   child: Text(
                    //     'Xem thêm',
                    //     style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                    //   ),
                    // ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: data.suggestedContents.take(5).length,
                itemBuilder: (context, index) {
                  return DiscoverTrendingListItem(item: data.suggestedContents[index]);
                },
              ),
            ],

            // --- 4. LỚP HỌC DÀNH CHO BẠN ---
            if (data.suggestedClasses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: Text(
                  'Lớp học dành cho bạn',
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: data.suggestedClasses.length,
                  itemBuilder: (context, index) {
                    return DiscoverClassroomCard(item: data.suggestedClasses[index]);
                  },
                ),
              ),
            ],

            const SizedBox(height: 80),
          ]),
        ),
      ],
    );
  }
}
