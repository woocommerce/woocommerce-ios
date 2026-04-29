import Foundation

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    init(unit: UnitLength, initial: ParcelDimensions = .unset) {
        self.unit = unit
        self.dimensions = initial
    }

    func resolveDefaults() {
        let defaults = Self.defaultDimensions(for: unit)
        if dimensions.length < 0 { dimensions.length = defaults.length }
        if dimensions.width < 0 { dimensions.width = defaults.width }
        if dimensions.height < 0 { dimensions.height = defaults.height }
    }

    var sliderRange: ClosedRange<Float> {
        unit == .inches ? 0.5...30.0 : 1.0...75.0
    }

    var dimensionsInMeters: SIMD3<Float> {
        resolvedDimensions.toMeters(unit: unit)
    }

    var confirmedDimensions: ParcelDimensions { resolvedDimensions }

    private var resolvedDimensions: ParcelDimensions {
        let defaults = Self.defaultDimensions(for: unit)
        return ParcelDimensions(
            length: dimensions.length >= 0 ? dimensions.length : defaults.length,
            width: dimensions.width >= 0 ? dimensions.width : defaults.width,
            height: dimensions.height >= 0 ? dimensions.height : defaults.height
        )
    }

    private static func defaultDimensions(for unit: UnitLength) -> ParcelDimensions {
        unit == .inches
            ? ParcelDimensions(length: 8.0, width: 6.0, height: 4.0)
            : ParcelDimensions(length: 20.0, width: 15.0, height: 10.0)
    }
}
