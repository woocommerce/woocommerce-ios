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
        unit == .inches
            ? ParcelDimensions(length: 8.0, width: 6.0, height: 4.0)
            : ParcelDimensions(length: 20.0, width: 15.0, height: 10.0)
    }

    private static func metersPerUnit(_ unit: UnitLength) -> Float {
        Float(Measurement(value: 1.0, unit: unit).converted(to: .meters).value)
    }
}
