import SwiftUI

struct PointOfSaleCollectCashView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var keyboardObserver = KeyboardObserver()

    private let viewHelper = CollectCashViewHelper()

    @State private var textFieldAmountInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var changeDueMessage: String?

    let orderTotal: String

    private var formattedOrderTotal: String {
        String.localizedStringWithFormat(Localization.backNavigationSubtitle, orderTotal)
    }

    private var keyboardHeight: CGFloat {
        if keyboardObserver.keyboardHeight < Constants.keyboardShownButtonSpacing {
            return Constants.keyboardShownButtonSpacing
        } else {
            return Constants.keyboardHiddenButtonSpacing
        }
    }

    @StateObject private var textFieldViewModel = FormattableAmountTextFieldViewModel(size: .extraLarge,
                                                                                      locale: Locale.autoupdatingCurrent,
                                                                                      storeCurrencySettings: ServiceLocator.currencySettings,
                                                                                      allowNegativeNumber: false)

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            HStack {
                Button(action: {
                    Task { @MainActor in
                        await posModel.cancelCashPayment()
                    }
                }, label: {
                    HStack(alignment: .top) {
                        Image(systemName: "chevron.backward")
                            .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                            .foregroundColor(.primary)
                        VStack(alignment: .leading) {
                            Text(Localization.backNavigationTitle)
                                .font(.posTitleEmphasized)
                                .foregroundColor(.posPrimaryText)
                                .accessibilityAddTraits(.isHeader)

                            Text(formattedOrderTotal)
                                .font(.posBodyRegular)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, -Constants.navigationButtonSpacing)
                    }
                })
                Spacer()
            }

            FormattableAmountTextField(viewModel: textFieldViewModel, style: .pos)
                .onChange(of: textFieldViewModel.amount) { newValue in
                    textFieldAmountInput = newValue
                    updateChangeDueMessage()
                }

            if let changeDue = changeDueMessage {
                Text(changeDue)
                    .font(.posBodyRegular)
                    .foregroundColor(.posSecondaryText)
            }

            Spacer().frame(height: keyboardHeight)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(POSFontStyle.posBodyRegular)
                    .foregroundColor(.red)
                    .padding(.bottom, Constants.errorMessagePadding)
            }

            Button(action: {
                Task { @MainActor in
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
                }
            }, label: {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(Color.posPrimaryTextInverted)
                    } else {
                        Text(Localization.markPaymentCompletedButtonTitle)
                            .font(Constants.buttonFont)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Constants.buttonMinHeight)
            })
            .padding(Constants.buttonPadding)
            .frame(maxWidth: .infinity)
            .foregroundColor(colorScheme == .light ? Color.white : Color.black)
            .background(Color.posPrimaryButtonBackground)
            .cornerRadius(Constants.buttonCornerRadius)
            .contentShape(Rectangle())
            .disabled(isLoading)

            Spacer()
        }
        .background(backgroundColor)
        .padding(.top, Constants.navigationHeaderTopPadding)
        .padding([.horizontal, .bottom])
        .animation(.easeInOut, value: errorMessage)
        .animation(.easeInOut, value: changeDueMessage)
        .animation(.easeInOut, value: keyboardObserver.keyboardHeight)
        .onChange(of: textFieldAmountInput) { _ in
            errorMessage = nil
        }
    }

    private func markComplete() async throws {
        try await posModel.collectCashPayment()
    }
}

private extension PointOfSaleCollectCashView {
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
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonMinHeight: CGFloat = 32
        static let navigationButtonSpacing: CGFloat = 8
        static let navigationHeaderTopPadding: CGFloat = 8
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
        static let errorMessagePadding: CGFloat = 8
        static let keyboardShownButtonSpacing: CGFloat = 80
        static let keyboardHiddenButtonSpacing: CGFloat = 20
    }

    private var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.posSecondaryBackground
        default:
            return .clear
        }
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
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    PointOfSaleCollectCashView(orderTotal: "$1.23")
        .environmentObject(posModel)
}
#endif
