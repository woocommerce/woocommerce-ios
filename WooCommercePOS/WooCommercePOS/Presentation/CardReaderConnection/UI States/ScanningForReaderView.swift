import SwiftUI

struct ScanningForReaderView: View {
    let cancel: () -> Void

    var body: some View {
        Text("Scanning for reader...")
        Button("Cancel search") {
            cancel()
        }
    }
}

#Preview {
    ScanningForReaderView(cancel: {})
}
