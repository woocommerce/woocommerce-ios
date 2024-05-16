import SwiftUI

struct ReaderConnectedView: View {
    let readerID: String
    let disconnect: () -> Void

    var body: some View {
        Text("Connected")
        Text(readerID)
            .bold()
        Button("Disconnect") {
            disconnect()
        }
    }
}

#Preview {
    ReaderConnectedView(readerID: "Test reader", disconnect: {})
}
