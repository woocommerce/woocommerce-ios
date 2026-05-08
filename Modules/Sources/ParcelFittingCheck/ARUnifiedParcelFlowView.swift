import SwiftUI

struct ARUnifiedParcelFlowView: View {
    let unit: UnitLength
    let carriers: [ParcelPresetCarrier]
    let starredPackageIDs: Set<String>
    var delegate: ParcelFittingDelegate?
    let onCancel: () -> Void
    let onConfirm: (ParcelFittingResult) -> Void

    @State private var measuredDimensions: ParcelDimensions?

    var body: some View {
        if let dims = measuredDimensions {
            NavigationView {
                ARParcelFittingResultsView(
                    viewModel: ARParcelFittingResultsViewModel(
                        measuredDimensions: dims,
                        unit: unit,
                        carriers: carriers
                    ),
                    starredPackageIDs: starredPackageIDs,
                    delegate: delegate,
                    onConfirm: onConfirm,
                    onBack: { measuredDimensions = nil }
                )
            }
            .navigationViewStyle(.stack)
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
