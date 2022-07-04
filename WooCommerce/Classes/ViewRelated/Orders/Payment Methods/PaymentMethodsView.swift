import SwiftUI

struct FeatureAnnouncementView: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("NEW")
                    .foregroundColor(Color(.textBrand))
                    .padding(.leading, 6)
                    .padding(.trailing, 6)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.withColorStudio(.wooCommercePurple, shade: .shade0))))
                    .font(.system(size: 12, weight: .bold))
                    .padding(.bottom, 16)
                Text("Accept Payments Easily")
                    .headlineStyle()
                    .padding(.bottom, 8)
                Text("Adopting in-person payments can help you grow your business.")
                    .font(.system(size: 15))
                    .padding(.bottom, 16)
                Button("Set up now") {}
            }
            .padding(.leading, 16)

            VStack(alignment: .trailing, spacing: 0) {
                Button(action: {
                          print("button pressed")
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color(.withColorStudio(.gray)))
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                Image(uiImage: .installWCShipImage)
            }
        }
        .background(Color(.listForeground))
    }
}

struct PaymentMethodsView: View {
    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Needed because IPP capture payments using a UIViewController for providing user feedback.
    ///
    weak var rootViewController: UIViewController?

    /// ViewModel to render the view content.
    ///
    @ObservedObject var viewModel: PaymentMethodsViewModel

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

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: Layout.noSpacing) {
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
                            viewModel.trackCollectByPaymentLink()
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(.listForeground))

                FeatureAnnouncementView()
            }

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
                    .frame(width: PaymentMethodsView.Layout.iconWidthHeight(scale: scale),
                           height: PaymentMethodsView.Layout.iconWidthHeight(scale: scale))
                    .foregroundColor(Color(.systemGray))
                    .accessibility(hidden: true)

                Text(title)
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                DisclosureIndicator()
            }
            .padding(.vertical, PaymentMethodsView.Layout.verticalPadding)
            .padding(.horizontal, insets: safeAreaInsets)
        }
    }
}

// MARK: Constants
extension PaymentMethodsView {
    enum Localization {
        static let header = NSLocalizedString("Choose your payment method", comment: "Heading text on the select payment method screen")
        static let cash = NSLocalizedString("Cash", comment: "Cash method title on the select payment method screen")
        static let card = NSLocalizedString("Card", comment: "Card method title on the select payment method screen")
        static let link = NSLocalizedString("Share Payment Link", comment: "Payment Link method title on the select payment method screen")
        static let markAsPaidTitle = NSLocalizedString("Mark as Paid?", comment: "Alert title when selecting the cash payment method")
        static let markAsPaidButton = NSLocalizedString("Mark as Paid", comment: "Alert button when selecting the cash payment method")
        static let cancelTitle = NSLocalizedString("Cancel", comment: "Title for the button to cancel the payment methods screen")
    }

    enum Layout {
        static let noSpacing: CGFloat = 0
        static let verticalPadding: CGFloat = 11

        static func iconWidthHeight(scale: CGFloat) -> CGFloat {
            24 * scale
        }
    }
}

// MARK: Previews
struct PaymentMethodsView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PaymentMethodsView(viewModel: .init(formattedTotal: "$15.99", flow: .orderPayment))
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        NavigationView {
            PaymentMethodsView(viewModel: .init(formattedTotal: "$15.99", flow: .orderPayment))
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")

        NavigationView {
            PaymentMethodsView(viewModel: .init(formattedTotal: "$15.99", flow: .orderPayment))
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        .previewDisplayName("Accessibility")
    }
}
