import SwiftUI

struct PointOfSaleCollectCashView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel

    @State private var textFieldAmountInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let orderTotal: String

    private var formattedOrderTotal: String {
        String.localizedStringWithFormat(Localization.backNavigationSubtitle, orderTotal)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack {
                Button(action: {
                    dismiss()
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

            TextField("$0.00", text: $textFieldAmountInput)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(POSFontStyle.posTitleRegular)
                .focused()
                .padding()
                .onSubmit {
                    Task { @MainActor in
                        await markComplete()
                    }
                }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(POSFontStyle.posBodyRegular)
                    .foregroundColor(.red)
            }

            Button(action: {
                Task { @MainActor in
                    await markComplete()
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
        .padding()
        .animation(.easeInOut, value: errorMessage)
        .onChange(of: textFieldAmountInput) { amount in
            errorMessage = nil
        }
    }

    private func markComplete() async {
        // TODO:
        // https://github.com/woocommerce/woocommerce-ios/issues/14602
    }
}

private extension PointOfSaleCollectCashView {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
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
    }
}

#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    PointOfSaleCollectCashView(orderTotal: "$1.23")
        .environmentObject(posModel)
}
