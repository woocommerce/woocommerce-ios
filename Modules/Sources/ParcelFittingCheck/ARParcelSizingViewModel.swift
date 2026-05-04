import Foundation

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    init(unit: UnitLength, initial: ParcelDimensions? = nil) {
        self.unit = unit
        self.dimensions = initial ?? Self.defaultDimensions(for: unit)
    }

    var sliderRange: ClosedRange<Float> {
        unit == .inches ? 0.5...30.0 : 1.0...75.0
    }

    var dimensionsInMeters: SIMD3<Float> {
        dimensions.toMeters(unit: unit)
    }

    var confirmedDimensions: ParcelDimensions { dimensions }

    private static func defaultDimensions(for unit: UnitLength) -> ParcelDimensions {
        unit == .inches
            ? ParcelDimensions(length: 8.0, width: 6.0, height: 4.0)
            : ParcelDimensions(length: 20.0, width: 15.0, height: 10.0)
    }
}
