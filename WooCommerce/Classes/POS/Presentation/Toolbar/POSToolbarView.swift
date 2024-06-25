import SwiftUI

struct POSToolbarView: View {
    @Environment(\.presentationMode) private var presentationMode
    private let readerConnectionViewModel: CardReaderConnectionViewModel
    @Binding private var isExitPOSDisabled: Bool

    init(readerConnectionViewModel: CardReaderConnectionViewModel,
         isExitPOSDisabled: Binding<Bool>) {
        self.readerConnectionViewModel = readerConnectionViewModel
        self._isExitPOSDisabled = isExitPOSDisabled
    }

    var body: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack(spacing: Layout.buttonImageAndTextSpacing) {
                    Image(uiImage: .swapHorizontal)
                    Text("Exit POS")
                }
            }
            .tint(Color(uiColor: .gray(.shade60)))
            .disabled(isExitPOSDisabled)

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
    POSToolbarView(readerConnectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()),
                   isExitPOSDisabled: .constant(false))
}

#endif
