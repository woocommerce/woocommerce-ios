import Foundation
import ParcelFittingCheck

struct ARSelectionState {
    let measurement: ParcelDimensions
    let carriers: [ParcelPresetCarrier]
    var starredPackageIDs: Set<String>
    let dimensionUnit: UnitLength
}
