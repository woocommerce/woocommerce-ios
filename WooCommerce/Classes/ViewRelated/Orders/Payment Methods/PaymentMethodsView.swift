import SwiftUI
import WooFoundation

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

    @State private var showingScanToPayView = false

    @State private var showingOtherPaymentMethodsView = false

    private let learnMoreViewModel = LearnMoreViewModel.inPersonPayments(source: .paymentMethods)

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.noSpacing) {

                Text(Localization.header)
                    .subheadlineStyle()
                    .padding()
                    .padding(.horizontal, insets: safeAreaInsets)
                    .accessibility(identifier: Accessibility.headerLabel)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: Layout.noSpacing) {
                        MethodRow(icon: .priceImage, title: Localization.cash, accessibilityID: Accessibility.cashMethod) {
                            showingCashAlert = true
                            viewModel.trackCollectByCash()
                        }
                        .fullScreenCover(isPresented: $showingCashAlert) {
                            CashPaymentTenderView(viewModel: CashPaymentTenderViewModel(formattedTotal: viewModel.formattedTotal) { info in
                                viewModel.markOrderAsPaidByCash(with: info) {
                                    dismiss()
                                }
                            })
                            .background(FullScreenCoverClearBackgroundView())
                        }

                        if viewModel.showPayWithCardRow {
                            Divider()

                            MethodRow(icon: .creditCardImage, title: Localization.card, accessibilityID: Accessibility.cardMethod) {
                                viewModel.collectPayment(using: .bluetoothScan, on: rootViewController, onSuccess: dismiss, onFailure: dismiss)
                            }
                        }

                        if viewModel.showTapToPayRow {
                            Divider()

                            MethodRow(icon: .tapToPayOnIPhoneIcon,
                                      title: Localization.tapToPay,
                                      accessibilityID: Accessibility.tapToPayMethod) {
                                viewModel.collectPayment(using: .localMobile, on: rootViewController, onSuccess: dismiss, onFailure: dismiss)
                            }
                        }

                        if viewModel.showPaymentLinkRow {
                            Divider()

                            MethodRow(icon: .linkImage, title: Localization.link, accessibilityID: Accessibility.paymentLink) {
                                sharingPaymentLink = true
                                viewModel.trackCollectByPaymentLink()
                            }
                        }

                        if viewModel.showScanToPayRow {
                            Divider()

                            MethodRow(icon: .scanToPayIcon, title: Localization.scanToPay, accessibilityID: Accessibility.scanToPayMethod) {
                                showingScanToPayView = true
                                viewModel.trackCollectByScanToPay()
                            }
                        }

                        Divider()

                        MethodRow(icon: .otherPaymentMethodsIcon, title: Localization.otherPaymentMethods, accessibilityID: Accessibility.otherPaymentMethods) {
                            showingOtherPaymentMethodsView = true
                            viewModel.trackCollectByScanToPay()
                        }
                    }
                    .padding(.horizontal)
                    .background(Color(.listForeground(modal: false)))

                    NavigationLink(destination: WebView(isPresented: .constant(true), url: learnMoreViewModel.url)
                                                .onAppear {
                                                    learnMoreViewModel.learnMoreTapped()
                                                }
                    ) {
                        AttributedText(learnMoreViewModel.learnMoreAttributedString)
                    }.padding(.horizontal)
                }

                // Pushes content to the top
                Spacer()
            }
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
        .fullScreenCover(isPresented: $showingScanToPayView) {
            ScanToPayView(viewModel: ScanToPayViewModel(paymentURL: viewModel.paymentLink)) {
                dismiss()
                viewModel.performScanToPayFinishedTasks()
            }
                .background(FullScreenCoverClearBackgroundView())
        }
        .fullScreenCover(isPresented: $showingOtherPaymentMethodsView) {
            OtherPaymentMethodsView(viewModel: OtherPaymentMethodsViewModel(formattedTotal: viewModel.formattedTotal) { noteText in
                viewModel.markOrderAsPaidWithOtherPaymentMethod(with: noteText) {
                    dismiss()
                }
            })
                .background(FullScreenCoverClearBackgroundView())
        }
    }
}

/// Represents a Payment method row
///
private struct MethodRow: View {
    /// Icon of the row
    ///
    private let icon: UIImage

    /// Title of the row
    ///
    private let title: String

    /// Accessibility ID for the row
    ///
    private let accessibilityID: String

    /// Action when the row is selected
    ///
    private let action: () -> ()

    /// Keeps track of the current screen scale.
    ///
    @ScaledMetric private var scale = 1

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    init(icon: UIImage, title: String, accessibilityID: String = "", action: @escaping () -> ()) {
        self.icon = icon
        self.title = title
        self.accessibilityID = accessibilityID
        self.action = action
    }

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
        .accessibilityIdentifier(accessibilityID)
    }
}

// MARK: Constants
extension PaymentMethodsView {
    enum Localization {
        static let header = NSLocalizedString("Choose your payment method", comment: "Heading text on the select payment method screen")
        static let cash = NSLocalizedString("Cash", comment: "Cash method title on the select payment method screen")
        static let card = NSLocalizedString("Card Reader",
                                            comment: "(External) card reader payment method title on the select payment method screen")
        static let tapToPay = NSLocalizedString("Tap to Pay on iPhone",
                                                comment: "Tap to Pay on iPhone method title on the select payment method screen")
        static let link = NSLocalizedString("Share Payment Link", comment: "Payment Link method title on the select payment method screen")
        static let scanToPay = NSLocalizedString("Scan to Pay", comment: "Scan to Pay method title on the select payment method screen")
        static let otherPaymentMethods = NSLocalizedString("paymentMethods.otherPaymentMethods.tyile",
                                                           value: "Other Payment Methods",
                                                           comment: "Other payment methods title on the select payment method screen")
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

    enum Accessibility {
        static let headerLabel = "payment-methods-header-label"
        static let cashMethod = "payment-methods-view-cash-row"
        static let cardMethod = "payment-methods-view-card-row"
        static let tapToPayMethod = "payment-methods-view-tap-to-pay-row"
        static let paymentLink = "payment-methods-view-payment-link-row"
        static let scanToPayMethod = "payment-methods-view-scan-to-pay-row"
        static let otherPaymentMethods = "payment-methods-other-payment-methods-row"
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
