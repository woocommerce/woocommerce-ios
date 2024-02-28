import Foundation

extension CustomerSelectorViewController.Configuration {
    static let configurationForOrderFilter = CustomerSelectorViewController.Configuration(
        title: OrderFilterLocalization.customerSelectorTitle,
        disallowSelectingGuest: true,
        disallowCreatingCustomer: true,
        showGuestLabel: true,
        shouldTrackCustomerAdded: false
    )

    enum OrderFilterLocalization {
        static let customerSelectorTitle = NSLocalizedString(
            "configurationForOrderFilter.customerSelectorTitle",
            value: "Choose a customer",
            comment: "Title for the screen to select customer in order filtering.")
    }
}
