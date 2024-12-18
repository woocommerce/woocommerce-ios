import SwiftUI

struct POSCollectCashView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel

    @State private var textFieldAmountInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack {
                Button(action: {
                    posModel.cancelCashPayment()
                }, label: {
                    HStack {
                        Image(systemName: "arrow.backward")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Cash payment")
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
                        Text("Mark payment as complete")
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
            debugPrint("🍍 \(amount)")
            // TODO:
            // Need to do amount validation for showing currency and decimal input
            errorMessage = nil
        }
    }

    private func markComplete() async {
        Task { @MainActor in
            try await posModel.markCashOrderAsPaid()
        }
    }
}

private extension POSCollectCashView {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
    }
}

#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    POSCollectCashView()
        .environmentObject(posModel)
}
