import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/image_search_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dòng ghi nguồn ảnh kho: "Ảnh: tác giả / Unsplash", theo quy định của kho ảnh.
/// Tên tác giả mở trang tác giả, tên kho mở trang ảnh. `credit` null (ảnh tự tải) thì không hiện gì.
class ImageCreditLine extends StatefulWidget {
  final ImageCredit? credit;
  final Color? color;
  final int maxLines;
  final TextAlign textAlign;

  const ImageCreditLine({
    super.key,
    required this.credit,
    this.color,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });

  @override
  State<ImageCreditLine> createState() => _ImageCreditLineState();
}

class _ImageCreditLineState extends State<ImageCreditLine> {
  final TapGestureRecognizer _authorTap = TapGestureRecognizer();
  final TapGestureRecognizer _photoTap = TapGestureRecognizer();

  @override
  void dispose() {
    _authorTap.dispose();
    _photoTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final credit = widget.credit;
    if (credit == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.onSurfaceVariant;
    final link = TextStyle(
      color: color,
      decoration: TextDecoration.underline,
      decorationColor: color,
    );
    _authorTap.onTap = () => _open(credit.authorUrl);
    _photoTap.onTap = () => _open(credit.photoUrl);

    return Text.rich(
      TextSpan(
        style: theme.textTheme.labelSmall?.copyWith(color: color),
        children: [
          TextSpan(text: 'image_credit_prefix'.tr),
          TextSpan(text: credit.authorName, style: link, recognizer: _authorTap),
          const TextSpan(text: ' / '),
          TextSpan(text: credit.sourceLabel, style: link, recognizer: _photoTap),
        ],
      ),
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.textAlign,
    );
  }
}
