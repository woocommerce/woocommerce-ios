import Foundation

/// Wrapper around MeasurementFormatter with a custom fallback in case there's an unrecognized unit
///
final class WeightFormatter {

    private let weightUnit: String
    private let formatter: MeasurementFormatter

    init(weightUnit: String, locale: Locale? = nil) {
        self.weightUnit = weightUnit
        formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        if let locale = locale {
            formatter.locale = locale
        }
    }

    /// Returns the formatted weight with the unit.
    /// The weight will be assumed to be zero if `nil` or empty..
    func formatWeight(weight: String?) -> String {
        let weight = coalesceWeight(weight)

        guard let unit = unit(symbol: weightUnit),
              let weightValue = Double(weight) else {
            return fallbackFormatWeight(weight: weight)
        }
        return formatWithFormatter(weight: weightValue, unit: unit)
    }
}

private extension WeightFormatter {
    func unit(symbol weightUnit: String) -> UnitMass? {
        switch weightUnit {
        case "g":
            return .grams
        case "kg":
            return .kilograms
        case "lb", "lbs":
            return .pounds
        case "oz":
            return .ounces
        default:
            return nil
        }
    }

    func formatWithFormatter(weight: Double, unit: UnitMass) -> String {
        let measurement = Measurement(value: weight, unit: unit)
        return formatter.string(from: measurement)
    }

    /// Returns the weight plus the unit.
    /// Only used if we don't recognize the unit as one of those supported by `UnitMass`
    func fallbackFormatWeight(weight: String) -> String {
        return weight + " " + weightUnit
    }

    func coalesceWeight(_ weight: String?) -> String {
        return (weight == nil || weight?.isEmpty == true) ? "0" : (weight ?? "0")
    }
}
