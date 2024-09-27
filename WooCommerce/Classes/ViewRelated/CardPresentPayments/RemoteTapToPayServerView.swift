import SwiftUI

struct RemoteTapToPayServerView: View {
    @ObservedObject var server: RemoteTapToPayReaderServer

    var body: some View {
        List {
            ForEach(server.serverMessages, id: \.self) { message in
                Text(message)
            }
        }
    }
}

#Preview {
    RemoteTapToPayServerView(server: RemoteTapToPayReaderServer())
}
