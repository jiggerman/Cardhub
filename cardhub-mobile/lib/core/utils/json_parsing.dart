/// DRF отдаёт DecimalField строкой ("818.00"), а IntegerField — числом.
/// Эти помощники приводят такие значения к нужному типу без падений.
double? asDouble(dynamic value) => switch (value) {
      num value => value.toDouble(),
      String value => double.tryParse(value),
      _ => null,
    };

int asInt(dynamic value, {int fallback = 0}) => switch (value) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? fallback,
      _ => fallback,
    };

String asString(dynamic value, {String fallback = ''}) => value is String ? value : fallback;

bool asBool(dynamic value, {bool fallback = false}) => value is bool ? value : fallback;
