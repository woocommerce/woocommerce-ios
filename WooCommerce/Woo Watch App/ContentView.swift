import SwiftUI
import NetworkingWatchOS

struct ContentView: View {

    @Environment(\.dependencies) private var dependencies

    @StateObject var viewModel: MyStoreViewModel

    init(dependencies: WatchDependencies) {
        _viewModel = StateObject(wrappedValue: MyStoreViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(viewModel.viewState.description)
        }
        .padding()
        .task {
            await viewModel.fetchStats()
        }
    }
}

#Preview {
    ContentView(dependencies: .fake())
}
