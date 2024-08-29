import SwiftUI

struct PointOfSaleCardPresentPaymentFoundReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posTitleEmphasized)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    Text(viewModel.description)
                        .font(POSFontStyle.posBodyRegular)
                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.connectButton.title,
                       action: viewModel.connectButton.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())

                Button(viewModel.continueSearchButton.title,
                       action: viewModel.continueSearchButton.actionHandler)
                .buttonStyle(POSSecondaryButtonStyle())
            }
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .posModalCloseButton(action: viewModel.cancelSearchButton.actionHandler,
                             accessibilityLabel: viewModel.cancelSearchButton.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentFoundReaderView(
        viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
            readerName: "READER NAME",
            connectAction: {},
            continueSearchAction: {},
            endSearchAction: {}),
        animation: .init(namespace: namespace)
    )
}
