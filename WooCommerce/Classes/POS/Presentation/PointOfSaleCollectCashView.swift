import SwiftUI
import class WooFoundation.CurrencyFormatter

struct PointOfSaleCollectCashView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @FocusState private var isTextFieldFocused: Bool

    @State private var textFieldAmountInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let currencyFormatter: CurrencyFormatter = WooFoundation.CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    let orderTotal: String

    private var formattedOrderTotal: String {
        String.localizedStringWithFormat(Localization.backNavigationSubtitle, orderTotal)
    }

    private func validateAmount() -> Bool {
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(textFieldAmountInput) else {
            errorMessage = "Invalid amount. Please try again."
            return false
        }
        switch inputDecimal.compare(orderDecimal) {
            case .orderedAscending:
                // inputDecimal < orderDecimal
                errorMessage = "Not enough cash to cover the order."
                return false
            case .orderedDescending:
                // inputDecimal > orderDecimal
                let changeDue = inputDecimal.subtracting(orderDecimal)
                errorMessage = "Change due: \(formatAsCurrency(changeDue))"
                return true
            case .orderedSame:
                // inputDecimal == orderDecimal
                errorMessage = nil
                return true
            }
    }

    @StateObject private var textFieldViewModel = FormattableAmountTextFieldViewModel(size: .extraLarge,
                                                                                      locale: Locale.autoupdatingCurrent,
                                                                                      storeCurrencySettings: ServiceLocator.currencySettings,
                                                                                      allowNegativeNumber: false)

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack {
                Button(action: {
                    posModel.addMoreToCart()
                }, label: {
                    VStack {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(Localization.backNavigationTitle)
                        }
                        .font(.posTitleRegular)
                        .bold()
                        .foregroundColor(.primary)

                        Text(formattedOrderTotal)
                            .font(.posBodyRegular)
                            .foregroundColor(.primary)
                    }
                })
                Spacer()
            }
            .padding()

            FormattableAmountTextField(viewModel: textFieldViewModel, style: .pos)
                .onChange(of: textFieldViewModel.amount) { newValue in
                    textFieldAmountInput = newValue
                }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(POSFontStyle.posBodyRegular)
                    .foregroundColor(.red)
            }

            Button(action: {
                Task { @MainActor in
                    guard validateAmount() else {
                        return
                    }
                    isLoading = true
                    do {
                        try await markComplete()
                        posModel.cashPaymentSuccess()
                    } catch {
                        errorMessage = Localization.failedToCollectCashPayment
                    }
                    isLoading = false
                }
            }, label: {
                HStack(spacing: Constants.buttonSpacing) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(Color.posPrimaryTextInverted)
                    } else {
                        Text(Localization.markPaymentCompletedButtonTitle)
                            .font(Constants.buttonFont)
                    }
                }
                .frame(maxWidth: .infinity)
            })
            .padding(Constants.buttonPadding)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.posPrimaryTextInverted)
            .background(Color.posOverlayFillInverted)
            .cornerRadius(Constants.buttonCornerRadius)
            .contentShape(Rectangle())
            .disabled(isLoading)

            Spacer()
        }
        .background(backgroundColor)
        .padding()
        .animation(.easeInOut, value: errorMessage)
        .onChange(of: textFieldAmountInput) { _ in
            errorMessage = nil
        }
    }

    private func markComplete() async throws {
        try await posModel.collectCashPayment()
    }
}

private extension PointOfSaleCollectCashView {
    func parseCurrency(_ amountString: String) -> NSDecimalNumber? {
        currencyFormatter.convertToDecimal(amountString, locale: .current)
    }

    private func formatAsCurrency(_ amount: NSDecimalNumber) -> String {
        currencyFormatter.formatAmount(amount) ?? "$0.00"
    }
}

private extension PointOfSaleCollectCashView {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
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
            "pointOfSale.cashview.failedToCollectCashPayment.draft",
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
