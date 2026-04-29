import Foundation

struct ParcelDimensions {
    var length: Float
    var width: Float
    var height: Float

    static let unset = ParcelDimensions(length: -1, width: -1, height: -1)

    var isResolved: Bool {
        length >= 0 && width >= 0 && height >= 0
    }

    func toMeters(unit: String) -> SIMD3<Float> {
        let factor = DimensionUnitConversion.metersPerUnit(unit)
        return SIMD3(length * factor, height * factor, width * factor)
    }
}
