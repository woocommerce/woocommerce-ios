import Foundation
import ParcelFittingCheck

struct ARPackageContext {
    let measurement: ParcelDimensions
    let carriers: [ParcelPresetCarrier]
    let starredPackageIDs: Set<String>
    let dimensionUnit: UnitLength
}
