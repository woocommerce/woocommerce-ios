import SwiftUI

struct FoundReadersView: View {
    let readerIDs: [String]
    let connect: (String) -> Void
    let continueSearch: () -> Void

    var body: some View {
        Text("Found readers")
        List {
            ForEach(readerIDs, id: \.self) { readerID in
                HStack {
                    Text(readerID)
                    Button("Connect") {
                        connect(readerID)
                    }
                }
            }
            Button("Keep Scanning") {
                continueSearch()
            }
        }
    }
}

#Preview {
    FoundReadersView(readerIDs: ["Test reader 1", "Test reader 2"],
                     connect: { _ in },
                     continueSearch: {})
}
