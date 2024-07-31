import SwiftUI

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView: View {
    private let viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.progressTitle)
            Text(viewModel.progressSubtitle)

            Button(viewModel.cancelButtonTitle,
                   action: {
                if let cancelReaderUpdate = viewModel.cancelReaderUpdate {
                    cancelReaderUpdate()
                } else {
                    dismiss()
                }
            })
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#if DEBUG

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressPreviewView: View {
    @State var showsSheet = false

    var body: some View {
        VStack {
            Button("Open view") {
                showsSheet = true
            }
        }
        .sheet(isPresented: $showsSheet) {
            PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView(viewModel: .init(
                progress: 0.6, cancel: nil
            ))
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressPreviewView()
}

#endif
