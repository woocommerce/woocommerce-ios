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
                        Image(systemName: "wave.3.forward.circle.fill")
                            .foregroundColor(.init(uiColor: .wooCommercePurple(.shade30)))
                        Text("Reader Connected")
                            .foregroundColor(.init(uiColor: .wooCommercePurple(.shade80)))
                    }
                case .disconnected:
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(Color.wooAmberShade40)
                            Text("Reader disconnected")
                                .foregroundColor(Color.wooAmberShade80)
                        }

                        Button {
                            connectionViewModel.connectReader()
                        } label: {
                            Text("Connect now")
                        }
                        .foregroundColor(Color(uiColor: .wooCommercePurple(.shade60)))
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
