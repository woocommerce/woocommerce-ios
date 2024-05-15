import SwiftUI
import NetworkingWatchOS

struct ContentView: View {

    @Environment(\.dependencies) private var dependencies

    let message: String = "Logged In"

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(message)
        }
        .padding()
        .task {
            if let credentials = dependencies.credentials {
                let service = StoreInfoDataService(credentials: credentials)
                do {
                    let stats = try await service.fetchTodayStats(for: dependencies.storeID!)
                    print(stats)
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
