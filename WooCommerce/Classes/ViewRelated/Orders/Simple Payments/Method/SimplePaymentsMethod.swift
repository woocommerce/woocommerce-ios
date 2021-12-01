import Foundation
import SwiftUI

/// View to choose what payment method will be used with the simple payments order.
///
struct SimplePaymentsMethod: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// ViewModel to render the view content.
    ///
    @ObservedObject var viewModel: SimplePaymentsMethodsViewModel

    /// Determines if the "pay by cash" alert confirmation should be shown.
    ///
    @State var showingCashAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.noSpacing) {

            Text(Localization.header)
                .subheadlineStyle()
                .padding()

            Divider()

            Group {
                MethodRow(icon: .priceImage, title: Localization.cash) {
                    showingCashAlert = true
                }

                Divider()

                MethodRow(icon: .creditCardImage, title: Localization.card) {
                    print("Tapped Card")
                }
            }
            .padding(.horizontal)
            .background(Color(.listForeground))

            Divider()

            // Pushes content to the top
            Spacer()
        }
        .disabled(viewModel.disableViewActions)
        .background(Color(.listBackground).ignoresSafeArea())
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                ProgressView()
                    .renderedIf(viewModel.showLoadingIndicator)
            }
        }
        .alert(isPresented: $showingCashAlert) {
            Alert(title: Text(Localization.markAsPaidTitle),
                  message: Text(viewModel.payByCashInfo()),
                  primaryButton: .cancel(),
                  secondaryButton: .default(Text(Localization.markAsPaidButton), action: {
                viewModel.markOrderAsPaid {
                    dismiss()
                }
            }))
        }
    }
}

/// Represents a Payment method row
///
private struct MethodRow: View {
    /// Icon of the row
    ///
    let icon: UIImage

    /// Title of the row
    ///
    let title: String

    /// Action when the row is selected
    ///
    let action: () -> ()

    /// Keeps track of the current screen scale.
    ///
    @ScaledMetric private var scale = 1

    var body: some View {
        Button(action: action) {
            HStack {
                Image(uiImage: icon)
                    .resizable()
                    .flipsForRightToLeftLayoutDirection(true)
                    .frame(width: SimplePaymentsMethod.Layout.iconWidthHeight(scale: scale),
                           height: SimplePaymentsMethod.Layout.iconWidthHeight(scale: scale))
                    .foregroundColor(Color(.systemGray))

                Text(title)
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(uiImage: .chevronImage)
                    .resizable()
                    .flipsForRightToLeftLayoutDirection(true)
                    .frame(width: SimplePaymentsMethod.Layout.chevronWidthHeight(scale: scale),
                           height: SimplePaymentsMethod.Layout.chevronWidthHeight(scale: scale))
                    .foregroundColor(Color(.systemGray))
            }
            .padding(.vertical, SimplePaymentsMethod.Layout.verticalPadding)
        }
    }
}

// MARK: Constants
private extension SimplePaymentsMethod {
    enum Localization {
        static let header = NSLocalizedString("Choose your payment method", comment: "Heading text on the select payment method screen for simple payments")
        static let cash = NSLocalizedString("Cash", comment: "Cash method title on the select payment method screen for simple payments")
        static let card = NSLocalizedString("Card", comment: "Card method title on the select payment method screen for simple payments")
        static let markAsPaidTitle = NSLocalizedString("Mark as Paid?", comment: "Alert title when selecting the cash payment method for simple payments")
        static let markAsPaidButton = NSLocalizedString("Mark as Paid", comment: "Alert button when selecting the cash payment method for simple payments")
    }

    enum Layout {
        static let noSpacing: CGFloat = 0
        static let verticalPadding: CGFloat = 11

        static func iconWidthHeight(scale: CGFloat) -> CGFloat {
            24 * scale
        }

        static func chevronWidthHeight(scale: CGFloat) -> CGFloat {
            22 * scale
        }
    }
}

// MARK: Previews
struct SimplePaymentsMethod_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SimplePaymentsMethod(viewModel: .init(formattedTotal: "$15.99"))
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        NavigationView {
            SimplePaymentsMethod(viewModel: .init(formattedTotal: "$15.99"))
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")

        NavigationView {
            SimplePaymentsMethod(viewModel: .init(formattedTotal: "$15.99"))
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        .previewDisplayName("Accessibility")
    }
}
