import SwiftUI

struct POSToolbarView: View {
    @Environment(\.presentationMode) private var presentationMode
    private let readerConnectionViewModel: CardReaderConnectionViewModel

    init(readerConnectionViewModel: CardReaderConnectionViewModel) {
        self.readerConnectionViewModel = readerConnectionViewModel
    }

    var body: some View {
        HStack {
            Button {
                // TODO: we need to cancel any prepared reader payment before we exit, or the reader can't be disconnected.
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack(spacing: Layout.buttonImageAndTextSpacing) {
                    Image(uiImage: .swapHorizontal)
                    Text("Exit POS")
                }
                .foregroundColor(Color(uiColor: .gray(.shade60)))
            }

            Spacer()

            CardReaderConnectionStatusView(connectionViewModel: readerConnectionViewModel)
        }
    }
}

private extension POSToolbarView {
    enum Layout {
        static let buttonImageAndTextSpacing: CGFloat = 12
    }
}

#if DEBUG

#Preview {
    POSToolbarView(readerConnectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()))
}

#endif
