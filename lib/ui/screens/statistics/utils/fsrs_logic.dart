import 'package:fl_chart/fl_chart.dart';

/// Lớp mô phỏng logic FSRS
class FsrsLogic {
  // Tính Khả năng truy xuất R (Retrievability) theo số ngày trôi qua (t) và Độ ổn định (S_old)
  static double calculateRetrievability(double tDays, double sOld) {
    return 1.0 / (1.0 + (tDays / (9.0 * sOld)));
  }

  // Generate data cho biểu đồ Đường cong quên lãng
  static List<FlSpot> generateForgettingCurveSpots(double sOld, int maxDays) {
    List<FlSpot> spots = [];
    for (int t = 0; t <= maxDays; t++) {
      double r = calculateRetrievability(t.toDouble(), sOld) * 100;
      spots.add(FlSpot(t.toDouble(), double.parse(r.toStringAsFixed(1))));
    }
    return spots;
  }
}
