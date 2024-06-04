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
                    Text("Reader connected")
                case .disconnected:
                    Button {
                        connectionViewModel.connectReader()
                    } label: {
                        Text("Reader disconnected")
                    }
            }
        }
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentService(siteID: 0)))
    }
}

#endif
