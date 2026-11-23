import 'package:flutter/widgets.dart';

/// Thanh thay thế thanh điều hướng dưới của `MainShell` (vd thanh hành động khi chọn nhiều ở Thư viện).
/// null: hiện thanh điều hướng bình thường. Màn nào đặt thì phải trả về null khi xong hoặc khi bị đóng.
final ValueNotifier<Widget?> bottomBarSlot = ValueNotifier(null);
