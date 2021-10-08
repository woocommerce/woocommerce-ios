import Foundation
import SwiftUI

/// Hosting controller that wraps an `QuickPayAmount` view.
///
final class QuickPayAmountHostingController: UIHostingController<QuickPayAmount> {

    init() {
        super.init(rootView: QuickPayAmount())

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View that receives an arbitrary amount for creating a quick pay order.
///
struct QuickPayAmount: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Temporary store for the typed amount
    ///
    @State private var amount: String = ""

    var body: some View {
        VStack(alignment: .center) {

            Spacer()

            Text(Localization.instructions)
                .secondaryBodyStyle()

            TextField(Localization.amountPlaceholder, text: $amount)
                .font(.system(size: 56, weight: .bold, design: .default))
                .foregroundColor(Color(.text))
                .fixedSize(horizontal: true, vertical: false)

            Spacer()

            Button(Localization.buttonTitle) {
                print("Done tapped")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .navigationTitle(Localization.title)
        .padding()
    }
}

// MARK: Constants
private extension QuickPayAmount {
    enum Localization {
        static let title = NSLocalizedString("Take Payment", comment: "Title for the quick pay screen")
        static let instructions = NSLocalizedString("Enter Amount", comment: "Short instructions label in the quick pay screen")
        static let amountPlaceholder = NSLocalizedString("$0.00", comment: "Placeholder for the amount textfield in the quick pay screen")
        static let buttonTitle = NSLocalizedString("Done", comment: "Title for the button to confirm the amount in the quick pay screen")
        static let cancelTitle = NSLocalizedString("Cancel", comment: "Title for the button to cancel the quick pay screen")
    }
}

// MARK: Previews
private struct QuickPayAmount_Preview: PreviewProvider {
    static var previews: some View {
        QuickPayAmount()
            .environment(\.colorScheme, .light)
    }
}
