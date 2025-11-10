import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
            PointOfSaleCardPresentPaymentReaderUpdateProgressView(
                progress: 1,
                isComplete: true
            )
            .accessibilityHidden(true)
            .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                Text(viewModel.title)
                    .font(POSFontStyle.posHeadingBold)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.progressTitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(POSFontStyle.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .posModalCloseButton(action: viewModel.buttonViewModel.actionHandler)
    }
}

#if DEBUG

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionPreviewView: View {
    @State var showsSheet = false
    @Namespace var namespace

    var body: some View {
        VStack {
            Button("Open view") {
                showsSheet = true
            }
        }
        .posSheet(isPresented: $showsSheet) {
            PointOfSaleCardPresentPaymentReaderUpdateCompletionView(
                viewModel: .init(doneAction: { showsSheet = false }),
                animation: .init(namespace: namespace)
            )
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateCompletionPreviewView()
}

#endif
