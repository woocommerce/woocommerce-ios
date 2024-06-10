import SwiftUI

enum CardReaderConnectionStatus {
    case connected
    case disconnected
}

struct CardReaderConnectionStatusView: View {
    @ObservedObject private var connectionViewModel: CardReaderConnectionViewModel

    init(connectionViewModel: CardReaderConnectionViewModel) {
        self.connectionViewModel = connectionViewModel
    }

    var body: some View {
        Group {
            switch connectionViewModel.connectionStatus {
                case .connected:
                    HStack(spacing: Layout.buttonImageAndTextSpacing) {
                        Image(systemName: "wave.3.forward.circle")
                        Text("Reader Connected")
                    }
                    .foregroundColor(.init(uiColor: .withColorStudio(.wooCommercePurple, shade: .shade10)))
                case .disconnected:
                    Button {
                        connectionViewModel.connectReader()
                    } label: {
                        Text("Reader Disconnected")
                            .foregroundColor(.init(uiColor: .withColorStudio(.wooCommercePurple, shade: .shade10)))
                    }
            }
        }
    }
}

private extension CardReaderConnectionStatusView {
    enum Layout {
        static let buttonImageAndTextSpacing: CGFloat = 12
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()))
    }
}

#endif
