import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/utils/image_url_utils.dart';
import 'package:mind_deck/data/models/image_search_model.dart';
import 'package:mind_deck/ui/commons/image_screens/image_credit_line.dart';

class CommonImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String baseUrl;

  /// Ghi nguồn khi ảnh từ kho ảnh.
  final ImageCredit? credit;

  const CommonImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    this.baseUrl = '',
    this.credit,
  });

  static void show(
    BuildContext context, {
    required List<String> images,
    required int initialIndex,
    String baseUrl = '',
    ImageCredit? credit,
  }) {
    showGeneralDialog(
      context: context,
      // Đặt trong suốt để ta tự điều khiển nền đen mờ dần khi kéo
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'common_close'.tr,
      // Thêm chút thời gian chuyển cảnh cho mượt
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: CommonImageViewer(
            images: images,
            initialIndex: initialIndex,
            baseUrl: baseUrl,
            credit: credit,
          ),
        );
      },
    );
  }

  @override
  State<CommonImageViewer> createState() => _CommonImageViewerState();
}

// Thêm SingleTickerProviderStateMixin để dùng AnimationController
class _CommonImageViewerState extends State<CommonImageViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool _isZoomed = false;
  bool _showUI = true;

  // ── Biến cho tính năng Kéo để đóng ──
  double _dragY = 0.0;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);

    // Khởi tạo animation đàn hồi khi kéo chưa đủ xa
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _snapController.addListener(() {
      setState(() {
        _dragY = _snapAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
  }

  // Xử lý khi bắt đầu vuốt dọc
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Nếu đang zoom ảnh thì KHÔNG cho kéo đóng
    if (_isZoomed) return;
    setState(() {
      _dragY += details.delta.dy;
      // Tự động ẩn UI khi bắt đầu kéo
      if (_showUI && _dragY.abs() > 10) _showUI = false;
    });
  }

  // Xử lý khi thả tay ra
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;

    // Nếu kéo đủ xa (hơn 150px) hoặc vuốt đủ nhanh -> Đóng
    if (_dragY.abs() > 150 || (details.primaryVelocity?.abs() ?? 0) > 800) {
      context.pop();
    } else {
      // Nếu chưa đủ xa -> Bật hoạt ảnh đàn hồi về 0
      _snapAnimation = Tween<double>(
        begin: _dragY,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic));
      _snapController.forward(from: 0.0);
      setState(() => _showUI = true); // Hiện lại UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Tính toán tỷ lệ mờ nền và tỷ lệ thu nhỏ dựa trên khoảng cách kéo
    final dragProgress = (_dragY.abs() / 400).clamp(0.0, 1.0);
    final bgOpacity = 1.0 - dragProgress;
    final scale = 1.0 - (dragProgress * 0.15);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: SafeArea(
        child: GestureDetector(
          // BÍ QUYẾT Ở ĐÂY: Nếu đang zoom thì gán null để không "cướp" sự kiện vuốt của ảnh
          onVerticalDragUpdate: _isZoomed ? null : _onVerticalDragUpdate,
          onVerticalDragEnd: _isZoomed ? null : _onVerticalDragEnd,

          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, _dragY, 0)
              ..scaleByDouble(scale, scale, 1.0, 1.0),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    String fullUrl = widget.images[index];
                    final isLocalFile =
                        fullUrl.startsWith('file://') ||
                        (fullUrl.startsWith('/') && File(fullUrl).existsSync());
                    if (!isLocalFile && !fullUrl.startsWith('http')) {
                      fullUrl = '${widget.baseUrl}$fullUrl';
                    }
                    return _ZoomableImagePage(
                      imageUrl: fullUrl,
                      onSingleTap: _toggleUI,
                      onZoomStateChanged: (isZoomed) {
                        if (_isZoomed != isZoomed) {
                          setState(() {
                            _isZoomed = isZoomed;
                            if (isZoomed) _showUI = false;
                          });
                        }
                      },
                    );
                  },
                ),

                // Ghi nguồn ảnh kho
                if (widget.credit != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: AnimatedOpacity(
                      opacity: _showUI ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showUI,
                        child: ImageCreditLine(
                          credit: widget.credit,
                          color: Colors.white,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                // Nút Đóng
                Positioned(
                  top: 16,
                  right: 16,
                  child: AnimatedOpacity(
                    opacity: _showUI ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showUI,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => context.pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bộ đếm ảnh
                Positioned(
                  top: 24,
                  left: 20,
                  child: AnimatedOpacity(
                    opacity: _showUI ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showUI,
                      child: AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          int currentIndex = _pageController.hasClients
                              ? (_pageController.page?.round() ?? widget.initialIndex)
                              : widget.initialIndex;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentIndex + 1} / ${widget.images.length}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.surface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget con đảm nhiệm việc Zoom cho từng bức ảnh (GIỮ NGUYÊN)
class _ZoomableImagePage extends StatefulWidget {
  final String imageUrl;
  final ValueChanged<bool> onZoomStateChanged;
  final VoidCallback onSingleTap;

  const _ZoomableImagePage({
    required this.imageUrl,
    required this.onZoomStateChanged,
    required this.onSingleTap,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
          ..addListener(() {
            if (_zoomAnimation != null) {
              _transformationController.value = _zoomAnimation!.value;
            }
          });

    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      widget.onZoomStateChanged(scale > 1.05);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;
    final position = _doubleTapDetails!.localPosition;
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final Matrix4 endMatrix;

    if (currentScale > 1.05) {
      endMatrix = Matrix4.identity();
    } else {
      const double targetScale = 2.5;
      final double x = -position.dx * (targetScale - 1);
      final double y = -position.dy * (targetScale - 1);

      endMatrix = Matrix4.translationValues(x, y, 0.0)
        ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0));
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));

    _animationController.forward(from: 0);
  }

  Widget _buildImage() {
    final colorScheme = Theme.of(context).colorScheme;
    final String url = widget.imageUrl;
    final isLocalFile =
        url.startsWith('file://') || (url.startsWith('/') && File(url).existsSync());
    if (isLocalFile) {
      final cleanPath = url.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, color: colorScheme.outline, size: 64),
      );
    }
    return Image.network(
      getImageUrl(url),
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const CircularProgressIndicator(color: Colors.white);
      },
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.broken_image, color: colorScheme.outline, size: 64),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSingleTap,
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(child: _buildImage()),
      ),
    );
  }
}
