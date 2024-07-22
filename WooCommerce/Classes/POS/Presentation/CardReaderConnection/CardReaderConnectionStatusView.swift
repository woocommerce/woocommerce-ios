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
                    Image(systemName: "circle.fill")
                        .resizable()
                        .frame(width: Layout.imageDimension * scale, height: Layout.imageDimension * scale)
                        .foregroundColor(Color.wooEmeraldShade40)
                    Text("Reader Connected")
                        .foregroundColor(Color.primaryText)
                }
            case .disconnected:
                Button {
                    connectionViewModel.connectReader()
                } label: {
                    HStack(spacing: Layout.buttonImageAndTextSpacing) {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: Layout.imageDimension * scale, height: Layout.imageDimension * scale)
                            .foregroundColor(Color.wooAmberShade60)
                        Text("Connect your reader")
                    }
                    .foregroundColor(Color(uiColor: .wooCommercePurple(.shade60)))
                }
            }
        }
        .font(.system(size: 16.0, weight: .semibold))
    }
}

private extension CardReaderConnectionStatusView {
    enum Layout {
        static let buttonImageAndTextSpacing: CGFloat = 12
        static let imageDimension: CGFloat = 12
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()))
    }
}

#endif
