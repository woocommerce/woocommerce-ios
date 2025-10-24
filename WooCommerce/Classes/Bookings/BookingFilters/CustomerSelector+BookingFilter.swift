import Foundation

extension CustomerSelectorViewController.Configuration {
    static let configurationForBookingFilter = CustomerSelectorViewController.Configuration(
        title: BookingFilterLocalization.customerSelectorTitle,
        disallowSelectingGuest: true,
        guestDisallowedMessage: BookingFilterLocalization.guestSelectionDisallowedError,
        disallowCreatingCustomer: true,
        showGuestLabel: true,
        shouldTrackCustomerAdded: false,
        isModal: false
    )

    enum BookingFilterLocalization {
        static let customerSelectorTitle = NSLocalizedString(
            "configurationForBookingFilter.customerName",
            value: "Customer name",
            comment: "Title for the screen to select customer in booking filtering."
        )
        static let guestSelectionDisallowedError = NSLocalizedString(
            "configurationForBookingFilter.guestSelectionDisallowedError",
            value: "This user is a guest, and guests can’t be used for filtering bookings.",
            comment: "Error message when selecting guest customer in booking filtering"
        )
    }
}
