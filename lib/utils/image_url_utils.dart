import 'package:mind_deck/constants/api_endpoints.dart';

/// Ảnh tự tải được BE trả đường dẫn tương đối (`/images/x.webp`), ảnh kho và thẻ cũ là URL đầy đủ.
String getImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return '${ApiEndpoints.url}$cleanPath';
}
