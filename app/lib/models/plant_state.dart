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
  final int nextWateringSeconds;

  PlantState({
    required this.mode,
    required this.intervalMinutes,
    required this.amountMl,
    required this.isWatering,
    required this.lastWateredSeconds,
    required this.nextWateringSeconds,
  });

  PlantState copyWith({
    PlantMode? mode,
    int? intervalMinutes,
    int? amountMl,
    bool? isWatering,
    int? lastWateredSeconds,
    int? nextWateringSeconds,
  }) {
    return PlantState(
      mode: mode ?? this.mode,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      amountMl: amountMl ?? this.amountMl,
      isWatering: isWatering ?? this.isWatering,
      lastWateredSeconds: lastWateredSeconds ?? this.lastWateredSeconds,
      nextWateringSeconds: nextWateringSeconds ?? this.nextWateringSeconds,
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

  // Convert seconds to human-readable time for next watering
  String get nextWateringTime {
    if (nextWateringSeconds == 0) return 'Not scheduled';

    if (nextWateringSeconds < 60) {
      return 'in $nextWateringSeconds seconds';
    }

    final days = nextWateringSeconds ~/ 86400;
    final hours = (nextWateringSeconds % 86400) ~/ 3600;
    final minutes = (nextWateringSeconds % 3600) ~/ 60;
    final seconds = nextWateringSeconds % 60;

    final parts = <String>[];
    if (days > 0) {
      parts.add('$days day${days > 1 ? 's' : ''}');
    }
    if (hours > 0) {
      parts.add('$hours hour${hours > 1 ? 's' : ''}');
    }
    if (minutes > 0) {
      parts.add('$minutes minute${minutes > 1 ? 's' : ''}');
    }
    if (seconds > 0 && days == 0 && hours == 0) {
      parts.add('$seconds second${seconds > 1 ? 's' : ''}');
    }

    return 'in ${parts.join(' ')}';
  }
}
