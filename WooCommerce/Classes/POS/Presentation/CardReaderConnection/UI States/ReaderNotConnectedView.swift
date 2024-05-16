import SwiftUI

struct ReaderNotConnectedView: View {
    let searchForReaders: () -> Void

    var body: some View {
        Text("Not connected to a reader")
        Button("Search for readers") {
            searchForReaders()
        }
    }
}

#Preview {
    ReaderNotConnectedView(searchForReaders: {})
}
