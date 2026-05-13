import SwiftUI

struct ARUnifiedParcelFlowView: View {
    let unit: UnitLength
    let carriers: [ParcelPresetCarrier]
    let starredPackageIDs: Set<String>
    let delegate: ParcelFittingDelegate
    let dismiss: () -> Void

    @State private var path = [ParcelDimensions]()

    var body: some View {
        NavigationStack(path: $path) {
            ARParcelSizingView(
                unit: unit,
                onCancel: {
                    dismiss()
                    delegate.parcelFittingDidCancel()
                },
                onConfirm: { dims in
                    path.append(dims)
                }
            )
            .navigationDestination(for: ParcelDimensions.self) { dims in
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
                    }
                )
            }
        }
    }
}
