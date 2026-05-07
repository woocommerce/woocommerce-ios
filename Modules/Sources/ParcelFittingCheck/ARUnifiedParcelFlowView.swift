import SwiftUI

struct ARUnifiedParcelFlowView: View {
    let unit: UnitLength
    let carriers: [ParcelPresetCarrier]
    let onCancel: () -> Void
    let onConfirm: (ParcelFittingResult) -> Void

    @State private var measuredDimensions: ParcelDimensions?

    var body: some View {
        if let dims = measuredDimensions {
            ARParcelFittingResultsView(
                viewModel: ARParcelFittingResultsViewModel(
                    measuredDimensions: dims,
                    unit: unit,
                    carriers: carriers
                ),
                onConfirm: onConfirm,
                onBack: { measuredDimensions = nil }
            )
        } else {
            ARParcelSizingView(
                unit: unit,
                onCancel: onCancel,
                onConfirm: { dims in
                    withAnimation { measuredDimensions = dims }
                }
            )
        }
    }
}
