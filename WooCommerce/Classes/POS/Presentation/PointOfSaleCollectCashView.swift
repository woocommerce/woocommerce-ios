import SwiftUI
import Combine
import WooFoundation

@available(iOS 17.0, *)
struct PointOfSaleCollectCashView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @FocusState private var isTextFieldFocused: Bool

    private let viewHelper = CollectCashViewHelper()

    @State private var textFieldAmountInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var changeDueMessage: String?

    let orderTotal: String

    @State private var buttonFrame: CGRect = .zero
    @State private var keyboardFrame: CGRect = .zero

    private var formattedOrderTotal: String {
        String.localizedStringWithFormat(Localization.backNavigationSubtitle, orderTotal)
    }

    @StateObject private var textFieldViewModel = FormattableAmountTextFieldViewModel(size: .extraLarge,
                                                                                      locale: Locale.autoupdatingCurrent,
                                                                                      storeCurrencySettings: ServiceLocator.currencySettings,
                                                                                      allowNegativeNumber: false)

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: conditionalPadding(13)) {
                POSPageHeaderView(title: Localization.backNavigationTitle,
                                  subtitle: formattedOrderTotal,
                                  backButtonConfiguration: .init(state: isLoading ? .disabled: .enabled,
                                                                 action: {
                    Task { @MainActor in
                        await posModel.cancelCashPayment()
                        isTextFieldFocused = false
                    }
                }))

                VStack(alignment: .center, spacing: conditionalPadding(62)) {
                    VStack(alignment: .center, spacing: conditionalPadding(4)) {
                        FormattableAmountTextField(viewModel: textFieldViewModel, style: .pos)
                            .focused($isTextFieldFocused)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            .onSubmit {
                                Task { @MainActor in
                                    await submitCashAmount()
                                }
                            }
                            .onChange(of: textFieldViewModel.amount) { newValue in
                                textFieldAmountInput = newValue
                                updateChangeDueMessage()
                            }

                        if let changeDue = changeDueMessage {
                            Text(changeDue)
                                .font(.posBodySmallRegular())
                                .foregroundColor(.posOnSurfaceVariantLowest)
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.posBodySmallRegular())
                                .foregroundColor(.posError)
                                .padding(.bottom, Constants.errorMessagePadding)
                        }
                    }

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
                    .frame(maxWidth: .infinity)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .disabled(isLoading)

                    Spacer()
                }
                .padding([.horizontal])
                .padding(.bottom, keyboardFrame.height)
            }
            .background(backgroundColor)
            .animation(.easeInOut, value: errorMessage)
            .animation(.easeInOut, value: changeDueMessage)
            .onChange(of: textFieldAmountInput) { _ in
                errorMessage = nil
            }
            .onReceive(Publishers.keyboardFrame) {
                keyboardFrame = $0
            }
        }
    }

    private func markComplete() async throws {
        try await posModel.collectCashPayment()
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleCollectCashView {
    private func submitCashAmount() async {
        guard validateAmountOnSubmit() else {
            return
        }
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

    private func validateAmountOnSubmit() -> Bool {
        viewHelper.validateAmountOnSubmit(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput,
            onError: { error in
                errorMessage = error
            })
        }
}

@available(iOS 17.0, *)
private extension PointOfSaleCollectCashView {
    enum Constants {
        static let buttonMinHeight: CGFloat = 32
        static let navigationButtonSpacing: CGFloat = 8
        static let navigationHeaderTopPadding: CGFloat = 8
        static let errorMessagePadding: CGFloat = 8
    }

    private func conditionalPadding(_ padding: CGFloat) -> CGFloat {
        if keyboardFrame.intersects(buttonFrame) {
            return 4
        }

        return padding
    }

    private var backgroundColor: Color {
        .posSurface
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
@available(iOS 17.0, *)
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    PointOfSaleCollectCashView(orderTotal: "$1.23")
        .environment(posModel)
}
#endif
