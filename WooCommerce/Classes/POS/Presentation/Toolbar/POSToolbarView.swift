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
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack(spacing: Layout.buttonImageAndTextSpacing) {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Exit POS")
                }
                .foregroundColor(Color.white)
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
