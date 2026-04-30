import SwiftUI
import UIKit
import WooFoundation

struct PointOfSaleScanToPayView: View {
    @Environment(\.posNavigationRouter) private var router
    @Environment(POSPaymentModel.self) private var paymentModel

    private let orderTotal: String
    private let screenBrightnessAtViewCreation = UIScreen.main.brightness

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    init(orderTotal: String) {
        self.orderTotal = orderTotal
    }

    var body: some View {
        content
            .onAppear {
                UIScreen.main.brightness = 1.0
            }
            .onDisappear {
                UIScreen.main.brightness = screenBrightnessAtViewCreation
            }
            .onChange(of: paymentModel.paymentState.scanToPay) { _, newValue in
                switch newValue {
                case .paymentSuccess:
                    router.popToRoot()
                case .idle:
                    router.popToRoot()
                case .showingQRCode:
                    break
                }
            }
    }

    private var content: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: POSSpacing.medium) {
                    POSPageHeaderView(
                        title: Localization.title,
                        subtitle: String.localizedStringWithFormat(Localization.subtitle, orderTotal),
                        backButtonConfiguration: .init(state: isLoading ? .disabled : .enabled,
                                                       action: {
                                                           Task { @MainActor in
                                                               await paymentModel.cancelScanToPayPayment()
                                                               router.popToRoot()
                                                           }
                                                       }))

                    Spacer()

                    qrCodeContent

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.posBodySmallRegular())
                            .foregroundColor(.posError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, POSPadding.medium)
                    }

                    Spacer()

                    Button(action: {
                        Task { @MainActor in
                            await markPaymentReceived()
                        }
                    }, label: {
                        Text(Localization.markPaymentCompletedButtonTitle)
                    })
                    .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))
                    .disabled(isLoading)
                    .padding([.horizontal, .bottom], POSPadding.medium)
                    .frame(maxWidth: .infinity)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                .frame(minHeight: geometry.size.height)
                .animation(.easeInOut, value: errorMessage)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var qrCodeContent: some View {
        if let qrImage = generatedQRCodeImage() {
            VStack(spacing: POSSpacing.small) {
                Text(Localization.scanInstruction)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)

                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: Layout.qrCodeSize, height: Layout.qrCodeSize)
                    .padding(POSPadding.medium)
                    .background(Color.white)
                    .cornerRadius(Layout.cornerRadius)
            }
            .padding(.horizontal, POSPadding.medium)
        } else {
            Text(Localization.qrUnavailable)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
                .padding(.horizontal, POSPadding.medium)
        }
    }

    private func generatedQRCodeImage() -> UIImage? {
        guard let url = paymentModel.scanToPayURL else { return nil }
        return url.generateQRCode()
    }
}

private extension PointOfSaleScanToPayView {
    @MainActor
    func markPaymentReceived() async {
        errorMessage = nil
        isLoading = true
        do {
            try await paymentModel.completeScanToPayPayment()
        } catch {
            errorMessage = Localization.failedToConfirmPayment
        }
        isLoading = false
    }
}

private extension PointOfSaleScanToPayView {
    enum Layout {
        static let qrCodeSize: CGFloat = 280
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.scanToPay.navigation.title",
            value: "Scan to Pay",
            comment: "Title for the Point of Sale scan-to-pay screen"
        )
        static let subtitle = NSLocalizedString(
            "pointOfSale.scanToPay.navigation.subtitle",
            value: "Total: %1$@",
            comment: "Subtitle showing the order total on the Point of Sale scan-to-pay screen. " +
            "Reads as 'Total: $1.23'"
        )
        static let scanInstruction = NSLocalizedString(
            "pointOfSale.scanToPay.scan.instruction",
            value: "Ask the customer to scan the QR code with their phone to complete the payment.",
            comment: "Instruction text shown above the QR code in the Point of Sale scan-to-pay screen."
        )
        static let qrUnavailable = NSLocalizedString(
            "pointOfSale.scanToPay.qrUnavailable.message",
            value: "We couldn't generate a QR code for this order. Please try a different payment method.",
            comment: "Message shown when no payment URL is available to render a QR code in Point of Sale scan-to-pay."
        )
        static let markPaymentCompletedButtonTitle = NSLocalizedString(
            "pointOfSale.scanToPay.markpaymentcompleted.button.title",
            value: "Mark payment as complete",
            comment: "Button to confirm a scan-to-pay payment was received in Point of Sale."
        )
        static let failedToConfirmPayment = NSLocalizedString(
            "pointOfSale.scanToPay.failedToConfirmPayment.errorMessage",
            value: "Error confirming payment. Try again.",
            comment: "Error message shown when confirming a scan-to-pay payment fails in Point of Sale."
        )
    }
}

#if DEBUG
#Preview {
    let model = POSPreviewHelpers.makePreviewAggregateModel()
    PointOfSaleScanToPayView(orderTotal: "$24.99")
        .environment(model.paymentModel)
}
#endif
