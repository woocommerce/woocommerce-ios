import Foundation

@Observable
final class ARParcelFitCheckViewModel {
    let unit: UnitLength
    let availableCarriers: [ParcelPresetCarrier]
    var selectedCarrierID: String?
    var selectedPackageID: String?

    init(unit: UnitLength, availableCarriers: [ParcelPresetCarrier], initialPackageID: String? = nil) {
        self.unit = unit
        self.availableCarriers = availableCarriers
        let carrier = availableCarriers.first { $0.packages.contains { $0.id == initialPackageID } }
            ?? availableCarriers.first
        self.selectedCarrierID = carrier?.id
        self.selectedPackageID = initialPackageID ?? carrier?.packages.first?.id
    }

    var currentCarrier: ParcelPresetCarrier? {
        availableCarriers.first { $0.id == selectedCarrierID }
    }

    var currentCarrierPackages: [ParcelPresetPackage] {
        currentCarrier?.packages ?? []
    }

    var currentPackage: ParcelPresetPackage? {
        currentCarrierPackages.first { $0.id == selectedPackageID }
    }

    func selectCarrier(_ id: String?) {
        selectedCarrierID = id
        selectedPackageID = currentCarrierPackages.first?.id
    }

    var dimensionsLabel: String? {
        guard let package = currentPackage else { return nil }
        return String(format: "%.1f × %.1f × %.1f %@", package.length, package.width, package.height, unit.symbol)
    }

    var dimensionsInMeters: SIMD3<Float> {
        let dims = currentPackage?.dimensions ?? .defaultDimensions(for: unit)
        return dims.toMeters(unit: unit)
    }
}
