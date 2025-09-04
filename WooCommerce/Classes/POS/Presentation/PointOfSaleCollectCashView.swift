import SwiftUI
import Combine
import WooFoundation

struct PointOfSaleCollectCashView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
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
    @State private var shouldMinimizePadding: Bool = false

    private var formattedOrderTotal: String {
        String.localizedStringWithFormat(Localization.backNavigationSubtitle, orderTotal)
    }

    @StateObject private var textFieldViewModel = FormattableAmountTextFieldViewModel(size: .extraLarge,
                                                                                      locale: Locale.autoupdatingCurrent,
                                                                                      storeCurrencySettings: ServiceLocator.currencySettings,
                                                                                      allowNegativeNumber: false)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                    POSPageHeaderView(title: Localization.backNavigationTitle,
                                      subtitle: formattedOrderTotal,
                                      backButtonConfiguration: .init(state: isLoading ? .disabled: .enabled,
                                                                     action: {
                        Task { @MainActor in
                            await posModel.cancelCashPayment()
                            isTextFieldFocused = false
                        }
                    }))

                    VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                        Spacer()

                        VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.xSmall)) {
                            FormattableAmountTextField(viewModel: textFieldViewModel, style: .pos)
                                .focused($isTextFieldFocused)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                .onSubmit {
                                    Task { @MainActor in
                                        await submitCashAmount()
                                    }
                                }
                                .onChange(of: textFieldViewModel.amount) { _, newValue in
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
                        .frame(maxWidth: .infinity)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .disabled(isLoading)
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
        try await posModel.collectCashPayment(changeDueAmount: changeDueAmount)
    }
}

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

    private var backgroundColor: Color {
        .posSurfaceBright
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
    PointOfSaleCollectCashView(orderTotal: "$1.23")
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
