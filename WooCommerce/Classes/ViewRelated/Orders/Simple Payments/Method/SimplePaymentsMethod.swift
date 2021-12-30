import Foundation
import SwiftUI

/// View to choose what payment method will be used with the simple payments order.
///
struct SimplePaymentsMethod: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Needed because IPP capture payments using a UIViewController for providing user feedback.
    ///
    weak var rootViewController: UIViewController?

    /// ViewModel to render the view content.
    ///
    @ObservedObject var viewModel: SimplePaymentsMethodsViewModel

    /// Determines if the "pay by cash" alert confirmation should be shown.
    ///
    @State var showingCashAlert = false

    /// Determines if the "share payment link" sheet should be shown.
    ///
    @State var sharingPaymentLink = false

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.noSpacing) {

            Text(Localization.header)
                .subheadlineStyle()
                .padding()
                .padding(.horizontal, insets: safeAreaInsets)

            Divider()

            Group {
                MethodRow(icon: .priceImage, title: Localization.cash) {
                    showingCashAlert = true
                    viewModel.trackCollectByCash()
                }

                if viewModel.showPayWithCardRow {
                    Divider()

                    MethodRow(icon: .creditCardImage, title: Localization.card) {
                        viewModel.collectPayment(on: rootViewController, onSuccess: dismiss)
                    }
                }

                if viewModel.showPaymentLinkRow {
                    Divider()

                    MethodRow(icon: .linkImage, title: Localization.link) {
                        sharingPaymentLink = true
                        // TODO: Analytics
                    }
                }
            }
            .padding(.horizontal)
            .background(Color(.listForeground))

            Divider()

            // Pushes content to the top
            Spacer()
        }
        .ignoresSafeArea(edges: .horizontal)
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
        .shareSheet(isPresented: $sharingPaymentLink) {
            // If paymentLink is available it already contains a valid URL.
            // CompactMap is required due to Swift URL APIs.
            ShareSheet(activityItems: [viewModel.paymentLink].compactMap { $0 } ) { _, completed, _, _ in
                if completed {
                    dismiss()
                    viewModel.performLinkSharedTasks()
                }
            }
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

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

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
            .padding(.horizontal, insets: safeAreaInsets)
        }
    }
}

// MARK: Constants
private extension SimplePaymentsMethod {
    enum Localization {
        static let header = NSLocalizedString("Choose your payment method", comment: "Heading text on the select payment method screen for simple payments")
        static let cash = NSLocalizedString("Cash", comment: "Cash method title on the select payment method screen for simple payments")
        static let card = NSLocalizedString("Card", comment: "Card method title on the select payment method screen for simple payments")
        static let link = NSLocalizedString("Payment Link", comment: "Payment Link method title on the select payment method screen for simple payments")
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
