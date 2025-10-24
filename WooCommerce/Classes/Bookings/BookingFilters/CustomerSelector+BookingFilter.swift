import Foundation

extension CustomerSelectorViewController.Configuration {
    static let configurationForBookingFilter = CustomerSelectorViewController.Configuration(
        title: BookingFilterLocalization.customerSelectorTitle,
        disallowSelectingGuest: true,
        disallowCreatingCustomer: true,
        showGuestLabel: true,
        shouldTrackCustomerAdded: false,
        isModal: false
    )

    enum BookingFilterLocalization {
        static let customerSelectorTitle = NSLocalizedString(
            "configurationForBookingFilter.customerName",
            value: "Customer name",
            comment: "Title for the screen to select customer in booking filtering.")
    }
}
