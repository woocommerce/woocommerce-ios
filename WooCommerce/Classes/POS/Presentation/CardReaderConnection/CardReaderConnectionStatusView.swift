import SwiftUI

enum CardReaderConnectionStatus {
    case connected
    case disconnected
}

struct CardReaderConnectionStatusView: View {
    @ObservedObject private var connectionViewModel: CardReaderConnectionViewModel
    @ScaledMetric private var scale: CGFloat = 1.0

    init(connectionViewModel: CardReaderConnectionViewModel) {
        self.connectionViewModel = connectionViewModel
    }

    var body: some View {
        Group {
            switch connectionViewModel.connectionStatus {
                case .connected:
                    HStack(spacing: Layout.buttonImageAndTextSpacing) {
                        Image(systemName: "wave.3.forward.circle.fill")
                            .resizable()
                            .frame(width: Layout.imageDimension * scale, height: Layout.imageDimension * scale)
                            .foregroundColor(.init(uiColor: .wooCommercePurple(.shade30)))
                        Text("Reader Connected")
                            .foregroundColor(.init(uiColor: .wooCommercePurple(.shade80)))
                    }
                case .disconnected:
                    HStack {
                        HStack(spacing: Layout.disconnectedTextAndButtonSpacing) {
                            Image(systemName: "bolt.fill")
                                .resizable()
                                .frame(width: Layout.imageDimension * scale, height: Layout.imageDimension * scale)
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
        static let disconnectedTextAndButtonSpacing: CGFloat = 8
        static let imageDimension: CGFloat = 16
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()))
    }
}

#endif
