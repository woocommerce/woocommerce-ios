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
            let service = StoreInfoDataService(credentials: dependencies.credentials)
            do {
                let stats = try await service.fetchTodayStats(for: dependencies.storeID)
                print(stats)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
