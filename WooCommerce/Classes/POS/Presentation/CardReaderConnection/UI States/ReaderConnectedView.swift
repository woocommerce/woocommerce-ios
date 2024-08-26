import SwiftUI

struct ReaderConnectedView: View {
    let readerID: String
    let disconnect: () -> Void

    var body: some View {
        Text("Connected")
            .font(POSFontStyle.posDetailLight)
        Text(readerID)
            .font(POSFontStyle.posDetailEmphasized)
        Button("Disconnect") {
            disconnect()
        }
    }
}

#Preview {
    ReaderConnectedView(readerID: "Test reader", disconnect: {})
}
