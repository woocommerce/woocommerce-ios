import Foundation
import SwiftUI

/// Hosting controller that wraps an `QuickPayAmount` view.
///
final class QuickPayAmountHostingController: UIHostingController<QuickPayAmount> {

    init(viewModel: QuickPayAmountViewModel) {
        super.init(rootView: QuickPayAmount(viewModel: viewModel))

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

    /// Keeps track of the current content scale due to accessibility changes
    ///
    @ScaledMetric private var scale: CGFloat = 1.0

    /// ViewModel to drive the view content
    ///
    @ObservedObject private(set) var viewModel: QuickPayAmountViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.mainVerticalSpacing) {

            Spacer()

            // Instructions Label
            Text(Localization.instructions)
                .secondaryBodyStyle()

            // Amount Textfield
            TextField(Localization.amountPlaceholder, text: $viewModel.amount)
                .font(.system(size: Layout.amountFontSize(scale: scale), weight: .bold, design: .default))
                .foregroundColor(Color(.text))
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)

            Spacer()

            // Done button
            Button(Localization.buttonTitle) {
                print("Done tapped")
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.amount == "$10"))
        }
        .padding()
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancelTitle, action: {
                    dismiss()
                })
            }
        }
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

    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
        static func amountFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
    }
}
