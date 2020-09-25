import UIKit

/// Displays a switch to enable shipping refunds
///
final class RefundShippingSwitchTableViewCell: UITableViewCell {

    /// Title describing the refund shipping switch
    ///
    @IBOutlet private var shippingTitle: UILabel!

    /// Control Enables / Disables the shipping refund
    ///
    @IBOutlet private var shippingSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyCellStyles()
    }
}

// MARK: View Configuration
private extension RefundShippingSwitchTableViewCell {
    func applyCellStyles() {
        applyDefaultBackgroundStyle()
        applyTitleStyles()
        shippingSwitch.onTintColor = .primary
    }

    func applyTitleStyles() {
        shippingTitle.applyBodyStyle()
        shippingTitle.text = Localization.shippingTitle
    }
}

// MARK: Actions
private extension RefundShippingSwitchTableViewCell {
    @IBAction func shippingSwitchValueChanged(_ sender: UISwitch) {
        // TODO: Forward action in a future PR
        print("Refund Shipping: \(sender.isOn)")
    }
}

// MARK: Constants
private extension RefundShippingSwitchTableViewCell {
    enum Localization {
        static let shippingTitle = NSLocalizedString("Refund Shipping", comment: "Title of the cell on the refund screen that toggles the shipping refund")
    }
}

// MARK: - Previews
#if canImport(SwiftUI) && DEBUG

import SwiftUI

private struct RefundShippingSwitchTableViewCellRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let nib = UINib(nibName: "RefundShippingSwitchTableViewCell", bundle: nil)
        guard let cell = nib.instantiate(withOwner: self, options: nil).first as? RefundShippingSwitchTableViewCell else {
            fatalError("Could not create RefundShippingSwitchTableViewCell")
        }
        return cell
    }

    func updateUIView(_ view: UIView, context: Context) {
        // no op
    }
}

@available(iOS 13.0, *)
struct RefundShippingSwitchTableViewCell_Previews: PreviewProvider {

    private static func makeStack() -> some View {
        VStack {
            RefundShippingSwitchTableViewCellRepresentable()
        }
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 359, height: 76))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 76))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 86))
                .environment(\.sizeCategory, .accessibilityMedium)
                .previewDisplayName("Large Font")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 160))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Extra Large Font")
        }
    }
}

#endif
