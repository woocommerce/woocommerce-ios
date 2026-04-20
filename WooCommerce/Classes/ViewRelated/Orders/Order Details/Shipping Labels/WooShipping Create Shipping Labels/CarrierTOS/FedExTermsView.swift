import SwiftUI

/// Convenience view that wraps `CarrierTermsView` with FedEx-specific checkbox configuration.
struct FedExTermsView: View {
    @ObservedObject var viewModel: FedExTermsViewModel
    let onConfirmation: () -> Void

    var body: some View {
        CarrierTermsView(viewModel: viewModel, checkboxes: { _ in
            LinkedCheckboxToggle(isOn: $viewModel.isTOSAccepted,
                                 labelFormat: FedExTermsViewModel.Localization.checkbox,
                                 linkText: FedExTermsViewModel.Localization.termsOfService,
                                 linkURL: FedExTermsViewModel.Links.termsOfService)
        }, onConfirmation: onConfirmation)
    }
}

#Preview {
    FedExTermsView(viewModel: FedExTermsViewModel(siteID: 123),
                   onConfirmation: {})
}
