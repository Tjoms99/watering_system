enum PlantMode {
  off,
  manual,
  scheduled,
}

class PlantState {
  final PlantMode mode;
  final int intervalMinutes;
  final int amountMl;
  final bool isWatering;
  final int lastWateredSeconds;

  PlantState({
    required this.mode,
    required this.intervalMinutes,
    required this.amountMl,
    required this.isWatering,
    required this.lastWateredSeconds,
  });

  PlantState copyWith({
    PlantMode? mode,
    int? intervalMinutes,
    int? amountMl,
    bool? isWatering,
    int? lastWateredSeconds,
  }) {
    return PlantState(
      mode: mode ?? this.mode,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      amountMl: amountMl ?? this.amountMl,
      isWatering: isWatering ?? this.isWatering,
      lastWateredSeconds: lastWateredSeconds ?? this.lastWateredSeconds,
    );
  }

  // Convert seconds to human-readable time
  String get lastWateredTime {
    if (lastWateredSeconds < 60) {
      return '$lastWateredSeconds seconds ago';
    } else if (lastWateredSeconds < 3600) {
      final minutes = lastWateredSeconds ~/ 60;
      return '$minutes minutes ago';
    } else {
      final hours = lastWateredSeconds ~/ 3600;
      return '$hours hours ago';
    }
  }
} 