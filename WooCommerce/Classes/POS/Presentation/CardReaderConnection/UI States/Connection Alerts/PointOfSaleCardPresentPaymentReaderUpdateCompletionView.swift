import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.progressTitle)

            Button(viewModel.dismissButtonTitle,
                   action: {
                dismiss()
            })
            .buttonStyle(SecondaryButtonStyle())
        }
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
