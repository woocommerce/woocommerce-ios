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
        guard let p = currentPackage else { return nil }
        return "\(p.length) × \(p.width) × \(p.height) \(unit.symbol)"
    }

    var dimensionsInMeters: SIMD3<Float> {
        guard let p = currentPackage else {
            return ParcelDimensions(length: 20, width: 15, height: 10).toMeters(unit: .centimeters)
        }
        return ParcelDimensions(
            length: Float(p.length) ?? 20,
            width: Float(p.width) ?? 15,
            height: Float(p.height) ?? 10
        ).toMeters(unit: unit)
    }
}
