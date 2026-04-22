/// Placeholder analytics payload — future: REST/GraphQL.
class MockAnalytics {
  const MockAnalytics({
    required this.totalFollowers,
    required this.growthToday,
    required this.weeklyGrowth,
    required this.dailySeries,
  });

  final int totalFollowers;
  final int growthToday;
  final int weeklyGrowth;

  /// X = day index, Y = follower count delta (mock).
  final List<FlSpotLite> dailySeries;

  static MockAnalytics sample() {
    return MockAnalytics(
      totalFollowers: 128_450,
      growthToday: 312,
      weeklyGrowth: 1840,
      dailySeries: const [
        FlSpotLite(0, 120),
        FlSpotLite(1, 95),
        FlSpotLite(2, 210),
        FlSpotLite(3, 140),
        FlSpotLite(4, 260),
        FlSpotLite(5, 180),
        FlSpotLite(6, 312),
      ],
    );
  }
}

/// Minimal point type to avoid importing fl_chart in mock layer.
class FlSpotLite {
  const FlSpotLite(this.x, this.y);
  final double x;
  final double y;
}
