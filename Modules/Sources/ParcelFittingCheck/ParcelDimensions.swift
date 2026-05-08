import Foundation

public struct ParcelDimensions {
    public var length: Float
    public var width: Float
    public var height: Float

    public init(length: Float, width: Float, height: Float) {
        self.length = length
        self.width = width
        self.height = height
    }

    func toMeters(unit: UnitLength) -> SIMD3<Float> {
        let factor = Self.metersPerUnit(unit)
        return SIMD3(length * factor, height * factor, width * factor)
    }

    static func fromMeters(_ meters: SIMD3<Float>, unit: UnitLength) -> ParcelDimensions {
        let factor = metersPerUnit(unit)
        return ParcelDimensions(
            length: meters.x / factor,
            width: meters.z / factor,
            height: meters.y / factor
        )
    }

    static func defaultDimensions(for unit: UnitLength) -> ParcelDimensions {
        switch unit {
        case .inches:
            return ParcelDimensions(length: 4.0, width: 3.0, height: 2.0)
        case .meters:
            return ParcelDimensions(length: 0.10, width: 0.08, height: 0.05)
        case .millimeters:
            return ParcelDimensions(length: 100.0, width: 80.0, height: 50.0)
        case .yards:
            return ParcelDimensions(length: 0.33, width: 0.25, height: 0.16)
        default:
            return ParcelDimensions(length: 10.0, width: 8.0, height: 5.0)
        }
    }

    private static let valueFormat = "%.2f"

    public static func formatValue(_ value: Float) -> String {
        String(format: valueFormat, value)
    }

    func formatted(unit: UnitLength) -> String {
        let l = Self.formatValue(length)
        let w = Self.formatValue(width)
        let h = Self.formatValue(height)
        return "\(l) × \(w) × \(h) \(unit.symbol)"
    }

    func formattedWithLabels(unit: UnitLength) -> String {
        let l = Self.formatValue(length)
        let w = Self.formatValue(width)
        let h = Self.formatValue(height)
        return "L: \(l)  W: \(w)  H: \(h) \(unit.symbol)"
    }

    private static func metersPerUnit(_ unit: UnitLength) -> Float {
        Float(Measurement(value: 1.0, unit: unit).converted(to: .meters).value)
    }
}
