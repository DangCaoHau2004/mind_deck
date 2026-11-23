import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/image_search_model.dart';
import 'package:mind_deck/ui/commons/image_screens/image_credit_line.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/image_search/image_search_bloc.dart';

/// Tìm ảnh từ kho ảnh, trả về ảnh người dùng chọn.
class ImageSearchSheet extends StatefulWidget {
  const ImageSearchSheet({super.key});

  static Future<ImageSearchResult?> show(BuildContext context) {
    return showModalBottomSheet<ImageSearchResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          BlocProvider(create: (_) => DI().sl<ImageSearchBloc>(), child: const ImageSearchSheet()),
    );
  }

  @override
  State<ImageSearchSheet> createState() => _ImageSearchSheetState();
}

class _ImageSearchSheetState extends State<ImageSearchSheet> {
  // Chờ người dùng ngừng gõ để đỡ tốn lượt, con số do thiết kế chọn, chưa đo.
  static const Duration _debounce = Duration(milliseconds: 500);

  final ScrollController _scroll = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<ImageSearchBloc>().add(const ImageSearchNextPageRequested());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) context.read<ImageSearchBloc>().add(ImageSearchQueryChanged(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'image_search_hint'.tr,
                  prefixIcon: const Icon(Icons.search_rounded),
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<ImageSearchBloc, ImageSearchState>(
                builder: (context, state) {
                  if (state.isLoading) return const Center(child: CircularProgressIndicator());
                  if (state.results.isEmpty) {
                    return _Message(
                      text:
                          state.error ??
                          (state.query.isEmpty ? 'image_search_start'.tr : 'image_search_empty'.tr),
                      color: state.error != null ? colorScheme.error : null,
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: state.results.length,
                          itemBuilder: (context, index) => _ImageTile(image: state.results[index]),
                        ),
                      ),
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(state.error!, style: TextStyle(color: colorScheme.error)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final ImageSearchResult image;

  const _ImageTile({required this.image});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context, image),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: image.thumbUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(color: colorScheme.surfaceContainer),
                errorWidget: (_, _, _) => ColoredBox(
                  color: colorScheme.surfaceContainer,
                  child: Icon(Icons.broken_image_outlined, color: colorScheme.outline),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ImageCreditLine(credit: image.credit),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Color? color;

  const _Message({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}
