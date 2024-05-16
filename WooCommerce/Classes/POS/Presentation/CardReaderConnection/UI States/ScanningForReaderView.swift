import SwiftUI

struct ScanningForReaderView: View {
    let cancel: () -> Void

    var body: some View {
        Text("Searching for reader")
        Button("Cancel") {
            cancel()
        }
    }
}

#Preview {
    ScanningForReaderView(cancel: {})
}
