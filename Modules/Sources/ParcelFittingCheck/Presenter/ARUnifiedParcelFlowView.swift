import SwiftUI

struct ARUnifiedParcelFlowView: View {
    let unit: UnitLength
    let carriers: [ParcelPresetCarrier]
    let starredPackageIDs: Set<String>
    let delegate: ParcelFittingDelegate
    let dismiss: () -> Void

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
                    onConfirm: { result in
                        dismiss()
                        delegate.parcelFittingDidConfirm(result,
                                                         carriers: carriers,
                                                         starredPackageIDs: starredPackageIDs,
                                                         dimensionUnit: unit)
                    },
                    onBack: { measuredDimensions = nil }
                )
            }
            .navigationViewStyle(.stack)
        } else {
            ARParcelSizingView(
                unit: unit,
                onCancel: {
                    dismiss()
                    delegate.parcelFittingDidCancel()
                },
                onConfirm: { dims in
                    withAnimation { measuredDimensions = dims }
                }
            )
        }
    }
}
