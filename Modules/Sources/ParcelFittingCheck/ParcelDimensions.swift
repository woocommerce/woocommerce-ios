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
        SIMD3(
            Self.meters(length, from: unit),
            Self.meters(height, from: unit),
            Self.meters(width, from: unit)
        )
    }

    private static func meters(_ value: Float, from unit: UnitLength) -> Float {
        Float(Measurement(value: Double(value), unit: unit).converted(to: .meters).value)
    }
}
