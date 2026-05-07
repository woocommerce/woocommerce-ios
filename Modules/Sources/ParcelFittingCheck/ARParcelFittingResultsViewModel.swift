import Foundation

@Observable
final class ARParcelFittingResultsViewModel {
    let measuredDimensions: ParcelDimensions
    let unit: UnitLength
    let carrierResults: [CarrierResult]

    struct CarrierResult: Identifiable {
        let carrier: ParcelPresetCarrier
        let package: ParcelPresetPackage
        var id: String { package.id }
    }

    init(measuredDimensions: ParcelDimensions, unit: UnitLength, carriers: [ParcelPresetCarrier]) {
        self.measuredDimensions = measuredDimensions
        self.unit = unit
        self.carrierResults = carriers.compactMap { carrier in
            guard let best = Self.smallestFitting(in: carrier.packages, for: measuredDimensions) else { return nil }
            return CarrierResult(carrier: carrier, package: best)
        }
        .sorted { $0.package.volume < $1.package.volume }
    }

    var dimensionsLabel: String {
        String(format: "%.1f × %.1f × %.1f %@",
               measuredDimensions.length, measuredDimensions.width, measuredDimensions.height,
               unit.symbol)
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
