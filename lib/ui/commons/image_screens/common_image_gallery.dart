import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'common_image_viewer.dart';
import 'package:mind_deck/utils/image_url_utils.dart';

class CommonImageGallery extends StatelessWidget {
  final List<String> images;
  final String baseUrl;

  // --- Cấu hình trạng thái rỗng ---
  final String emptyDescKey;
  final Widget? emptyWidget;

  // --- Cấu hình hiển thị Lưới (Grid) ---
  final int maxDisplayCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  // --- Cấu hình trang trí Ảnh (Decoration) ---
  final double borderRadius;
  final BoxBorder? imageBorder;
  final List<BoxShadow>? imageShadow;
  final BoxFit imageFit;
  final Widget? errorPlaceholder;

  const CommonImageGallery({
    super.key,
    required this.images,
    this.baseUrl = '',
    this.emptyDescKey = 'no_images_desc',
    this.emptyWidget,
    this.maxDisplayCount = 10,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
    this.childAspectRatio = 4 / 3,
    this.borderRadius = 10.0,
    this.imageBorder,
    this.imageShadow,
    this.imageFit = BoxFit.cover,
    this.errorPlaceholder,
  });

  Widget _buildImageWidget(String path, ColorScheme colorScheme) {
    if (path.isEmpty) return _buildErrorPlaceholder(colorScheme);
    // nếu là các dạng đó hoặc có thực sự tồn tại trên máy
    final isLocalFile =
        path.startsWith('file://') || (path.startsWith('/') && File(path).existsSync());

    if (isLocalFile) {
      final cleanPath = path.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        fit: imageFit,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(colorScheme),
      );
    }
    // nếu có dạng http hoặc https thì là network
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: imageFit,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(colorScheme),
      );
    }
    // mặc định là như này và nếu lỗi thì nó hiển thị trang lỗi
    return Image.network(
      baseUrl.isEmpty ? getImageUrl(path) : '$baseUrl$path',
      fit: imageFit,
      errorBuilder: (_, _, _) => _buildErrorPlaceholder(colorScheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Trạng thái KHÔNG CÓ ẢNH
    if (images.isEmpty) {
      if (emptyWidget != null) return emptyWidget!;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.image_not_supported_outlined, color: colorScheme.outlineVariant, size: 36),
            const SizedBox(height: 8),
            Text(
              emptyDescKey.tr,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final displayCount = images.length > maxDisplayCount ? maxDisplayCount : images.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final item = images[index];

        return GestureDetector(
          onTap: () {
            if (item.isNotEmpty) {
              CommonImageViewer.show(
                context,
                images: images,
                initialIndex: index,
                baseUrl: baseUrl,
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: imageBorder,
              boxShadow: imageShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                imageBorder != null ? (borderRadius - 1).clamp(0.0, double.infinity) : borderRadius,
              ),
              child: _buildImageWidget(item, colorScheme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(ColorScheme colorScheme) {
    if (errorPlaceholder != null) return errorPlaceholder!;
    return Container(
      color: colorScheme.surfaceContainer,
      child: Icon(Icons.image, color: colorScheme.outline, size: 40),
    );
  }
}
