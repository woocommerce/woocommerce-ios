import Foundation

@Observable
final class ARParcelSizingViewModel {
    var unit: String
    var dimensions: ParcelDimensions

    init(unit: String, initial: ParcelDimensions = .unset) {
        self.unit = unit
        self.dimensions = initial
    }

    func resolveDefaults() {
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        if dimensions.length < 0 { dimensions.length = defaults.length }
        if dimensions.width < 0 { dimensions.width = defaults.width }
        if dimensions.height < 0 { dimensions.height = defaults.height }
    }

    var sliderRange: ClosedRange<Float> {
        DimensionUnitConversion.sliderRange(for: unit)
    }

    var dimensionsInMeters: SIMD3<Float> {
        resolvedDimensions.toMeters(unit: unit)
    }

    var confirmedDimensions: ParcelDimensions {
        resolvedDimensions
    }

    private var resolvedDimensions: ParcelDimensions {
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        return ParcelDimensions(
            length: dimensions.length >= 0 ? dimensions.length : defaults.length,
            width: dimensions.width >= 0 ? dimensions.width : defaults.width,
            height: dimensions.height >= 0 ? dimensions.height : defaults.height
        )
    }
}
