import SwiftUI

/// Convenience view that wraps `CarrierTermsView` with UPS-specific checkbox configuration.
struct UPSTermsView: View {
    @ObservedObject var viewModel: UPSTermsViewModel
    let onConfirmation: () -> Void

    var body: some View {
        CarrierTermsView(viewModel: viewModel, checkboxes: { _ in
            LinkedCheckboxToggle(isOn: $viewModel.isTOSAccepted,
                                 labelFormat: UPSTermsViewModel.Localization.checkbox1,
                                 linkText: UPSTermsViewModel.Localization.termsOfService,
                                 linkURL: UPSTermsViewModel.Links.termsOfService)
            LinkedCheckboxToggle(isOn: $viewModel.isProhibitedItemsAccepted,
                                 labelFormat: UPSTermsViewModel.Localization.checkbox2,
                                 linkText: UPSTermsViewModel.Localization.prohibitedItems,
                                 linkURL: UPSTermsViewModel.Links.prohibitedItems)
            LinkedCheckboxToggle(isOn: $viewModel.isTechnologyAgreementAccepted,
                                 labelFormat: UPSTermsViewModel.Localization.checkbox3,
                                 linkText: UPSTermsViewModel.Localization.technologyAgreement,
                                 linkURL: UPSTermsViewModel.Links.techAgreement)
        }, onConfirmation: onConfirmation)
    }
}

#Preview {
    UPSTermsView(viewModel: UPSTermsViewModel(siteID: 123,
                                              originAddress: .init(company: "A8C",
                                                                   name: "John Doe",
                                                                   email: "test@mail.com",
                                                                   phone: "09381734543",
                                                                   country: "US",
                                                                   state: "New York",
                                                                   address1: "1 E 35th St",
                                                                   address2: "",
                                                                   city: "New York",
                                                                   postcode: "10028")),
                 onConfirmation: {})
}
