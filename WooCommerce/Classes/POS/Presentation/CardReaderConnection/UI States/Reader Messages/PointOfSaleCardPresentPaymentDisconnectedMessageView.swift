import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posPrimaryText)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.instruction)
                    .font(.posBodyRegular)
                    .foregroundStyle(Color.posPrimaryText)
            }

            Button {
                posModel.connectCardReader()
            } label: {
                Text(viewModel.connectReaderButtonTitle)
            }
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemProvider: POSItemProviderPreview(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderService: POSOrderPreviewService())
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView()
        .environmentObject(posModel)
}
#endif
