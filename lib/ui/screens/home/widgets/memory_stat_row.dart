import 'dart:async';

import 'package:flutter/material.dart';

/// Một ô chỉ số trên khối "Cần ôn hôm nay".
class MemoryStatItem {
  final IconData icon;
  final String value;
  final String label;

  /// Chú thích trong bong bóng khi chạm vào ô.
  final String info;

  const MemoryStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.info,
  });
}

/// Hàng ô chỉ số trên nền màu chính. Chạm một ô: ô chuyển sang nền trắng và hiện bong bóng
/// có mũi tên chỉ đúng ô; tự tắt sau [_showFor] hoặc khi chạm ra ngoài / chạm lại ô đó.
class MemoryStatRow extends StatefulWidget {
  final List<MemoryStatItem> items;

  const MemoryStatRow({super.key, required this.items});

  @override
  State<MemoryStatRow> createState() => _MemoryStatRowState();
}

class _MemoryStatRowState extends State<MemoryStatRow> with SingleTickerProviderStateMixin {
  static const Duration _showFor = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 200);
  static const double _spacing = 8;
  static const double _bubbleWidth = 240;
  static const double _arrowWidth = 16;
  static const double _arrowHeight = 8;

  final _overlay = OverlayPortalController();
  final _tapGroup = Object();
  late final List<LayerLink> _links = List.generate(widget.items.length, (_) => LayerLink());
  late final AnimationController _anim = AnimationController(vsync: this, duration: _animDuration);
  late final Animation<double> _curved = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );

  int? _selected;
  Timer? _autoHide;
  double _tileWidth = 0;

  /// Tăng mỗi lần mở/đóng để lần đóng cũ (đang chạy animation) không đè lên lần mở mới.
  int _token = 0;

  @override
  void dispose() {
    _autoHide?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _toggle(int index) {
    if (_selected == index) {
      _hide();
      return;
    }
    _token++;
    setState(() => _selected = index);
    _overlay.show();
    _anim.forward(from: 0);
    _autoHide?.cancel();
    _autoHide = Timer(_showFor, _hide);
  }

  void _hide() {
    _autoHide?.cancel();
    if (_selected == null) return;
    final token = ++_token;
    // Ô trở lại màu cũ cùng lúc bong bóng mờ đi.
    setState(() => _selected = null);
    _anim.reverse().whenCompleteOrCancel(() {
      if (!mounted || token != _token) return;
      _overlay.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) => _hide(),
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildBubble,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final n = widget.items.length;
            _tileWidth = (constraints.maxWidth - _spacing * (n - 1)) / n;
            return Row(
              children: [
                for (int i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: _spacing),
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _links[i],
                      child: _StatTile(
                        item: widget.items[i],
                        selected: _selected == i,
                        onTap: () => _toggle(i),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Bong bóng nằm dưới ô; ô đầu canh trái, ô cuối canh phải để không tràn màn, mũi tên luôn chỉ giữa ô.
  Widget _buildBubble(BuildContext context) {
    // Giữ ô cuối cùng đã chọn trong lúc bong bóng đang mờ đi.
    final index = _selected ?? _lastShown;
    if (index == null) return const SizedBox.shrink();
    _lastShown = index;
    final item = widget.items[index];
    final last = widget.items.length - 1;

    final Alignment targetAnchor;
    final Alignment followerAnchor;
    final double arrowCenter;
    if (index == 0) {
      targetAnchor = Alignment.bottomLeft;
      followerAnchor = Alignment.topLeft;
      arrowCenter = _tileWidth / 2;
    } else if (index == last) {
      targetAnchor = Alignment.bottomRight;
      followerAnchor = Alignment.topRight;
      arrowCenter = _bubbleWidth - _tileWidth / 2;
    } else {
      targetAnchor = Alignment.bottomCenter;
      followerAnchor = Alignment.topCenter;
      arrowCenter = _bubbleWidth / 2;
    }

    return Positioned(
      width: _bubbleWidth,
      child: CompositedTransformFollower(
        link: _links[index],
        showWhenUnlinked: false,
        targetAnchor: targetAnchor,
        followerAnchor: followerAnchor,
        offset: const Offset(0, 6),
        child: TapRegion(
          groupId: _tapGroup,
          child: FadeTransition(
            opacity: _anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(_curved),
              alignment: Alignment(arrowCenter / _bubbleWidth * 2 - 1, -1),
              child: _Bubble(
                title: item.label,
                message: item.info,
                arrowLeft: arrowCenter - _arrowWidth / 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _lastShown;
}

/// Ô chỉ số: thường là nền trắng mờ chữ trắng; được chọn thì nền trắng chữ màu chính, có vòng sáng.
class _StatTile extends StatelessWidget {
  final MemoryStatItem item;
  final bool selected;
  final VoidCallback onTap;

  const _StatTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onCard = colorScheme.onPrimary;
    final foreground = selected ? colorScheme.primary : onCard;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _MemoryStatRowState._animDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.surface : onCard.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            // Vòng sáng quanh ô đang chọn.
            BoxShadow(color: onCard.withValues(alpha: selected ? 0.4 : 0), spreadRadius: 3),
          ],
        ),
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: foreground),
          duration: _MemoryStatRowState._animDuration,
          builder: (context, color, _) {
            final fg = color ?? foreground;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 22, color: fg),
                    const Spacer(),
                    Icon(Icons.info_outline_rounded, size: 18, color: fg.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: textTheme.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: selected ? colorScheme.onSurface : fg.withValues(alpha: 0.85),
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bong bóng trắng có mũi tên phía trên.
class _Bubble extends StatelessWidget {
  final String title;
  final String message;
  final double arrowLeft;

  const _Bubble({required this.title, required this.message, required this.arrowLeft});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: arrowLeft),
          child: CustomPaint(
            size: const Size(_MemoryStatRowState._arrowWidth, _MemoryStatRowState._arrowHeight),
            painter: _ArrowPainter(color: colorScheme.surface),
          ),
        ),
        Material(
          color: colorScheme.surface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
