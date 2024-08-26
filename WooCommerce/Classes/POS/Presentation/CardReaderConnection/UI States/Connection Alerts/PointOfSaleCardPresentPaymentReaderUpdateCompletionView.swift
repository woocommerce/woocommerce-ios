import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            viewModel.image
                .accessibilityHidden(true)

            Text(viewModel.progressTitle)
                .font(POSFontStyle.posBodyRegular)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionPreviewView: View {
    @State var showsSheet = false

    var body: some View {
        VStack {
            Button("Open view") {
                showsSheet = true
            }
        }
        .sheet(isPresented: $showsSheet) {
            PointOfSaleCardPresentPaymentReaderUpdateCompletionView(viewModel: .init())
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateCompletionPreviewView()
}

#endif
