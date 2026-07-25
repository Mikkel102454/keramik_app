import 'package:ceramic_app/objects/account_settings_dto.dart';

class Measurement {
  const Measurement._();

  static const double poundsPerKilogram = 2.2046226218487757;

  static double lengthFromCentimeters(
    double centimeters,
    MeasurementSystem system,
  ) => system == MeasurementSystem.imperial ? centimeters / 2.54 : centimeters;

  static double lengthToCentimeters(
    double displayValue,
    MeasurementSystem system,
  ) => system == MeasurementSystem.imperial ? displayValue * 2.54 : displayValue;

  static double temperatureFromCelsius(
    double celsius,
    MeasurementSystem system,
  ) => system == MeasurementSystem.imperial ? celsius * 9 / 5 + 32 : celsius;

  static double temperatureToCelsius(
    double displayValue,
    MeasurementSystem system,
  ) => system == MeasurementSystem.imperial
      ? (displayValue - 32) * 5 / 9
      : displayValue;

  static double weightFromKilograms(
    double kilograms,
    MeasurementSystem system,
  ) => system == MeasurementSystem.imperial
      ? kilograms * poundsPerKilogram
      : kilograms;

  static double weightToKilograms(
    double displayValue,
    MeasurementSystem system,
  ) => system == MeasurementSystem.imperial
      ? displayValue / poundsPerKilogram
      : displayValue;

  static String format(double value) {
    final rounded = value.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }
}
