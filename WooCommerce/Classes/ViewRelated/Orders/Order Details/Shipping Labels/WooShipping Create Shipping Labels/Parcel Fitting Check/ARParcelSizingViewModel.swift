import Foundation

@Observable
final class ARParcelSizingViewModel {
    var unit: String = "in"
    var length: Float
    var width: Float
    var height: Float

    init(initialLength: Float? = nil, initialWidth: Float? = nil, initialHeight: Float? = nil) {
        self.length = initialLength ?? -1
        self.width = initialWidth ?? -1
        self.height = initialHeight ?? -1
    }

    func resolveDefaults() {
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        if length < 0 { length = defaults.length }
        if width < 0 { width = defaults.width }
        if height < 0 { height = defaults.height }
    }

    var sliderRange: ClosedRange<Float> {
        DimensionUnitConversion.sliderRange(for: unit)
    }

    var dimensionsInMeters: SIMD3<Float> {
        let factor = DimensionUnitConversion.metersPerUnit(unit)
        let r = resolvedDimensions
        return SIMD3(r.length * factor, r.height * factor, r.width * factor)
    }

    var confirmedDimensions: (length: Double, width: Double, height: Double) {
        let r = resolvedDimensions
        return (Double(r.length), Double(r.width), Double(r.height))
    }

    private var resolvedDimensions: (length: Float, width: Float, height: Float) {
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        return (
            length >= 0 ? length : defaults.length,
            width >= 0 ? width : defaults.width,
            height >= 0 ? height : defaults.height
        )
    }
}
