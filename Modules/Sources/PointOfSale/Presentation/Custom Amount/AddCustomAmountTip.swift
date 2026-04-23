import TipKit

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
