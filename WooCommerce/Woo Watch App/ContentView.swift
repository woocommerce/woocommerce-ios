import SwiftUI
import NetworkingWatchOS

struct ContentView: View {

    let message: String = "Hello Woo"

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(message)
        }
        .padding()
        .task {
            let credentials = Credentials(authToken: "6789")
            print("I can compile some credentials: \(credentials)")
        }
    }
}

#Preview {
    ContentView()
}
