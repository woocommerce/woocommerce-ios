import SwiftUI

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView: View {
    private let viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            Spacer()
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                viewModel.image
                    .accessibilityHidden(true)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posTitleEmphasized)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                        Text(viewModel.progressTitle)
                            .font(POSFontStyle.posBodyRegular)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(viewModel.progressSubtitle)
                            .font(POSFontStyle.posBodyRegular)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.cancelButtonTitle,
                   action: {
                if let cancelReaderUpdate = viewModel.cancelReaderUpdate {
                    cancelReaderUpdate()
                }
            })
            .buttonStyle(POSSecondaryButtonStyle())
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressPreviewView: View {
    @State var showsSheet = false
    @Namespace var namespace

    var body: some View {
        VStack {
            Button("Open view") {
                showsSheet = true
            }
        }
        .sheet(isPresented: $showsSheet) {
            PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView(viewModel: .init(
                progress: 0.6, cancel: nil
            ), animation: .init(namespace: namespace))
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressPreviewView()
}

#endif
