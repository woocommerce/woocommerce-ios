import Foundation

@Observable
final class ARParcelFitCheckViewModel {
    var unit: String
    let availableCarriers: [ParcelPresetCarrier]
    var selectedCarrierID: String?
    var selectedPackageID: String?

    init(unit: String, availableCarriers: [ParcelPresetCarrier], initialPackageID: String? = nil) {
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
        guard let p = currentPackage else { return nil }
        return "\(p.length) × \(p.width) × \(p.height) \(unit)"
    }

    var dimensionsInMeters: SIMD3<Float> {
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        guard let p = currentPackage else {
            return ParcelDimensions(length: defaults.length, width: defaults.width, height: defaults.height)
                .toMeters(unit: unit)
        }
        return ParcelDimensions(
            length: Float(p.length) ?? defaults.length,
            width: Float(p.width) ?? defaults.width,
            height: Float(p.height) ?? defaults.height
        ).toMeters(unit: unit)
    }
}
