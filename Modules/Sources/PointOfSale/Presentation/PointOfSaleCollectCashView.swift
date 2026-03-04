import SwiftUI
import Combine
import WooFoundation

struct PointOfSaleCollectCashView: View {
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(POSPaymentModel.self) private var paymentModel
    @FocusState private var isTextFieldFocused: Bool

    private let viewHelper: CollectCashViewHelper
    private let currencyInputSanitizer: CurrencyInputSanitizer
    private let presetAmount: Decimal?

    @State private var textFieldAmountInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var changeDueMessage: String?

    private let orderTotal: String

    @State private var buttonFrame: CGRect = .zero
    @State private var keyboardFrame: CGRect = .zero
    @State private var shouldMinimizePadding: Bool = false

    private var formattedOrderTotal: String {
        String.localizedStringWithFormat(Localization.backNavigationSubtitle, orderTotal)
    }

    private var isButtonEnabled: Bool {
        viewHelper.isPaymentButtonEnabled(orderTotal: orderTotal,
                                          textFieldAmountInput: textFieldAmountInput,
                                          isLoading: isLoading)
    }

    init(orderTotal: String, currencySettings: CurrencySettings) {
        self.viewHelper = CollectCashViewHelper(currencySettings: currencySettings)
        self.currencyInputSanitizer = CurrencyInputSanitizer(currencySettings: currencySettings)
        self.presetAmount = viewHelper.parseCurrency(orderTotal)
        self.orderTotal = orderTotal
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                    POSPageHeaderView(title: Localization.backNavigationTitle,
                                      subtitle: formattedOrderTotal,
                                      backButtonConfiguration: .init(state: isLoading ? .disabled: .enabled,
                                                                     action: {
                        isTextFieldFocused = false
                        Task { @MainActor in
                            await paymentModel.cancelCashPayment()
                        }
                    }))

                    VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                        Spacer()

                        VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.xSmall)) {
                            POSCashAmountTextField(
                                amount: $textFieldAmountInput,
                                isFocused: $isTextFieldFocused,
                                sanitizer: currencyInputSanitizer,
                                preset: presetAmount,
                                onSubmit: {
                                    Task { @MainActor in
                                        await submitCashAmount()
                                    }
                                }
                            )

                            if let changeDue = changeDueMessage {
                                Text(changeDue)
                                    .font(.posBodySmallRegular())
                                    .foregroundColor(.posOnSurfaceVariantLowest)
                            }

                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.posBodySmallRegular())
                                    .foregroundColor(.posError)
                            }
                        }

                        Spacer()

                        Button(action: {
                            Task { @MainActor in
                                await submitCashAmount()
                            }
                        }, label: {
                            Text(Localization.markPaymentCompletedButtonTitle)
                        })
                        .measureFrame {
                            buttonFrame = $0
                        }
                        .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))
                        .accessibilityIdentifier("pos-mark-payment-complete-button")
                        .frame(maxWidth: .infinity)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .disabled(!isButtonEnabled)
                    }
                    .padding([.horizontal])
                    .padding(.bottom, max(keyboardFrame.height - geometry.safeAreaInsets.bottom,
                                          floatingControlAreaSize.height) + Constants.bottomPadding
                    )
                }
                .frame(minHeight: geometry.size.height)
                .animation(.easeInOut, value: errorMessage)
                .animation(.easeInOut, value: changeDueMessage != nil)
                .onChange(of: textFieldAmountInput) {
                    errorMessage = nil
                    updateChangeDueMessage()
                }
                .onReceive(Publishers.keyboardFrame) {
                    keyboardFrame = $0
                    shouldMinimizePadding = $0.intersects(buttonFrame)
                }
                .animation(.default, value: shouldMinimizePadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func markComplete() async throws {
        let changeDueAmount = viewHelper.formattedChangeDueAmount(orderTotal: orderTotal,
                                                                  textFieldAmountInput: textFieldAmountInput)
        try await paymentModel.collectCashPayment(changeDueAmount: changeDueAmount)
    }
}

private extension PointOfSaleCollectCashView {
    private func submitCashAmount() async {
        analytics.track(.pointOfSaleCashPaymentTapped)
        isLoading = true
        do {
            try await markComplete()
        } catch {
            errorMessage = Localization.failedToCollectCashPayment
        }
        isLoading = false
        isTextFieldFocused = false
    }

    private func updateChangeDueMessage() {
        changeDueMessage = viewHelper.updatechangeDueMessage(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput)
    }
}

private extension PointOfSaleCollectCashView {
    enum Constants {
        static let minimumPadding: CGFloat = POSSpacing.xSmall
        static let bottomPadding: CGFloat = POSPadding.medium
    }

    private func conditionalPadding(_ padding: CGFloat) -> CGFloat {
        if shouldMinimizePadding {
            return Constants.minimumPadding
        }

        return padding
    }

    enum Localization {
        static let backNavigationTitle = NSLocalizedString(
            "pointOfSale.cashview.back.navigation.title",
            value: "Cash payment",
            comment: "Title for the cash payment view navigation back button"
        )
        static let backNavigationSubtitle = NSLocalizedString(
            "pointOfSale.cashview.back.navigation.subtitle",
            value: "Total: %1$@",
            comment: "Subtitle for the cash payment view navigation back button" +
            "Reads as 'Total: $1.23'"
        )
        static let markPaymentCompletedButtonTitle = NSLocalizedString(
            "pointOfSale.cashview.button.markpaymentcompleted.title",
            value: "Mark payment as complete",
            comment: "Button to mark a cash payment as completed"
        )
        static let failedToCollectCashPayment = NSLocalizedString(
            "pointOfSale.cashview.failedtocollectcashpayment.errormessage",
            value: "Error trying to process payment. Try again.",
            comment: "Error message when the system fails to collect a cash payment."
        )
    }
}

#if DEBUG
#Preview {
    let model = POSPreviewHelpers.makePreviewAggregateModel()
    PointOfSaleCollectCashView(orderTotal: "$1.23", currencySettings: CurrencySettings())
        .environment(model.paymentModel)
}
#endif
