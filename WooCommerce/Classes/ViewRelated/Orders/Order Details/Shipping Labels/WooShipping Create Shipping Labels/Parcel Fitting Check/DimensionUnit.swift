import Foundation

enum DimensionUnit {
    case inches
    case centimeters

    init(storeUnit: String) {
        switch storeUnit.lowercased() {
        case "in", "yd":
            self = .inches
        default:
            self = .centimeters
        }
    }

    var displayLabel: String {
        switch self {
        case .inches:      return "in"
        case .centimeters: return "cm"
        }
    }

    var metersPerUnit: Float {
        switch self {
        case .inches:      return 0.0254
        case .centimeters: return 0.01
        }
    }

    var sliderRange: ClosedRange<Float> {
        switch self {
        case .inches:      return 0.5...30.0
        case .centimeters: return 1.0...75.0
        }
    }

    var defaultDimensions: ParcelDimensions {
        switch self {
        case .inches:      return ParcelDimensions(length: 8.0, width: 6.0, height: 4.0)
        case .centimeters: return ParcelDimensions(length: 20.0, width: 15.0, height: 10.0)
        }
    }

    /// Converts a value from the store's raw unit string to this
    /// DimensionUnit. E.g. if the store uses "mm" and we're `.centimeters`,
    /// multiply by 0.1.
    func convert(_ value: Float, fromStoreUnit storeUnit: String) -> Float {
        let storeMeters = Self.metersPerStoreUnit(storeUnit)
        return value * storeMeters / metersPerUnit
    }

    private static func metersPerStoreUnit(_ unit: String) -> Float {
        switch unit.lowercased() {
        case "in":  return 0.0254
        case "cm":  return 0.01
        case "mm":  return 0.001
        case "m":   return 1.0
        case "yd":  return 0.9144
        default:    return 0.0254
        }
    }
}
