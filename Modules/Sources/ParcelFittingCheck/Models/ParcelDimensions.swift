import Foundation

public struct ParcelDimensions: Hashable {
    public var length: Float
    public var width: Float
    public var height: Float

    public init(length: Float, width: Float, height: Float) {
        self.length = length
        self.width = width
        self.height = height
    }

    public static func formatValue(_ value: Float) -> String {
        String.localizedStringWithFormat(Constants.valueFormat, value)
    }

    // MARK: - Internal

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
        let base = Constants.defaultInCentimeters
        let factor = Float(Measurement(value: 1.0, unit: UnitLength.centimeters).converted(to: unit).value)
        return ParcelDimensions(
            length: (base.length * factor * 100).rounded() / 100,
            width: (base.width * factor * 100).rounded() / 100,
            height: (base.height * factor * 100).rounded() / 100
        )
    }

    func formatted(unit: UnitLength) -> String {
        "\(Self.formatValue(length)) × \(Self.formatValue(width)) × \(Self.formatValue(height)) \(unit.symbol)"
    }

    func formattedWithLabels(unit: UnitLength) -> String {
        "\(Localization.lengthLabel): \(Self.formatValue(length))  " +
        "\(Localization.widthLabel): \(Self.formatValue(width))  " +
        "\(Localization.heightLabel): \(Self.formatValue(height)) \(unit.symbol)"
    }

    // MARK: - Private

    private enum Constants {
        static let defaultInCentimeters = ParcelDimensions(length: 10.0, width: 8.0, height: 5.0)
        static let valueFormat = "%.2f"
    }

    private static func metersPerUnit(_ unit: UnitLength) -> Float {
        Float(Measurement(value: 1.0, unit: unit).converted(to: .meters).value)
    }

    private enum Localization {
        static let lengthLabel = NSLocalizedString(
            "parcelFitting.dimensions.lengthLabel",
            value: "L",
            comment: "Abbreviation for Length in dimension display")
        static let widthLabel = NSLocalizedString(
            "parcelFitting.dimensions.widthLabel",
            value: "W",
            comment: "Abbreviation for Width in dimension display")
        static let heightLabel = NSLocalizedString(
            "parcelFitting.dimensions.heightLabel",
            value: "H",
            comment: "Abbreviation for Height in dimension display")
    }
}
