import SwiftUI

/// Convenience view that wraps `CarrierTermsView` with FedEx-specific checkbox configuration.
struct FedExTermsView: View {
    @ObservedObject var viewModel: FedExTermsViewModel
    let onConfirmation: () -> Void

    var body: some View {
        CarrierTermsView(viewModel: viewModel, checkboxes: { vm in
            LinkedCheckboxToggle(isOn: Binding(get: { vm.isTOSAccepted },
                                               set: { vm.isTOSAccepted = $0 }),
                                 labelFormat: FedExTermsViewModel.Localization.checkbox,
                                 linkText: FedExTermsViewModel.Localization.termsOfService,
                                 linkURL: FedExTermsViewModel.Links.termsOfService)
        }, onConfirmation: onConfirmation)
    }
}
