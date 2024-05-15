import SwiftUI

struct FoundReadersView: View {
    let readerIDs: [String]

    var body: some View {
        List {
            ForEach(readerIDs, id: \.self) { readerID in
                HStack {
                    Text(readerID)
                    Button("Connect") {
                        // TODO: connect action
                    }
                }
            }
        }
    }
}

#Preview {
    FoundReadersView(readerIDs: ["Test reader 1", "Test reader 2"])
}
