import TipKit

/// TipKit tip that points to the POS cart header button for adding a custom
/// amount. Invalidated permanently when the user taps the button (via
/// `.actionPerformed`) or the popover's close button (via TipKit's built-in
/// `.tipClosed`). If the user dismisses the popover by tapping outside, the
/// tip remains eligible and can reappear at most once per day because
/// `Tips.configure` uses the default `.daily` display frequency.
struct AddCustomAmountTip: Tip {
    var title: Text {
        Text(Localization.title)
    }

    var message: Text? {
        Text(Localization.message)
    }

    var image: Image? {
        Image(systemName: "plus.circle")
    }
}

private extension AddCustomAmountTip {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.addCustomAmountTip.title",
            value: "Add a custom amount",
            comment: "Title for the TipKit popover pointing to the add-custom-amount button in the Point of Sale cart header.")
        static let message = NSLocalizedString(
            "pos.addCustomAmountTip.message",
            value: "Tap here to add a service fee, tip, or any custom line to the order.",
            comment: "Body text for the TipKit popover pointing to the add-custom-amount button in the Point of Sale cart header.")
    }
}
