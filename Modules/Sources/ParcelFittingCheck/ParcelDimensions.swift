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

    private static func metersPerUnit(_ unit: UnitLength) -> Float {
        Float(Measurement(value: 1.0, unit: unit).converted(to: .meters).value)
    }
}
