import Foundation

@Observable
final class ARParcelFitCheckViewModel {
    var unit: String = "in"
    let availableCarriers: [ParcelPresetCarrier]
    var selectedCarrierID: String?
    var selectedPackageID: String?

    init(availableCarriers: [ParcelPresetCarrier], initialPackageID: String? = nil) {
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
        let factor = DimensionUnitConversion.metersPerUnit(unit)
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        guard let p = currentPackage else {
            return SIMD3(defaults.length * factor, defaults.height * factor, defaults.width * factor)
        }
        let l = (Float(p.length) ?? defaults.length) * factor
        let w = (Float(p.width) ?? defaults.width) * factor
        let h = (Float(p.height) ?? defaults.height) * factor
        return SIMD3(l, h, w)
    }
}
