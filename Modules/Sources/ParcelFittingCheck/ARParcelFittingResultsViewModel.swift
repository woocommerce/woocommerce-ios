import Foundation

@Observable
public final class ARParcelFittingResultsViewModel {
    public let measuredDimensions: ParcelDimensions
    public let unit: UnitLength
    public let carrierResults: [CarrierResult]

    public struct CarrierResult: Identifiable {
        public let carrier: ParcelPresetCarrier
        public let package: ParcelPresetPackage
        public var id: String { package.id }
    }

    public init(measuredDimensions: ParcelDimensions, unit: UnitLength, carriers: [ParcelPresetCarrier]) {
        self.measuredDimensions = measuredDimensions
        self.unit = unit
        self.carrierResults = carriers.compactMap { carrier in
            guard let best = Self.smallestFitting(in: carrier.packages, for: measuredDimensions) else { return nil }
            return CarrierResult(carrier: carrier, package: best)
        }
        .sorted { $0.package.volume < $1.package.volume }
    }

    var dimensionsLabel: String {
        measuredDimensions.formatted(unit: unit)
    }

    static func fits(measured: ParcelDimensions, into package: ParcelPresetPackage) -> Bool {
        let m = [measured.length, measured.width, measured.height].sorted(by: >)
        let p = [package.length, package.width, package.height].sorted(by: >)
        return p[0] >= m[0] && p[1] >= m[1] && p[2] >= m[2]
    }

    static func smallestFitting(in packages: [ParcelPresetPackage], for measured: ParcelDimensions) -> ParcelPresetPackage? {
        packages
            .filter { fits(measured: measured, into: $0) }
            .min { $0.volume < $1.volume }
    }
}
