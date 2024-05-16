import SwiftUI
import NetworkingWatchOS

struct MyStoreView: View {

    @Environment(\.dependencies) private var dependencies

    @StateObject var viewModel: MyStoreViewModel

    init(dependencies: WatchDependencies) {
        _viewModel = StateObject(wrappedValue: MyStoreViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack {

            Text(dependencies.storeName)
            Text("Revenue")
            Text("$4,321.90")

            Divider()

            HStack {
                Text("Today")
                Spacer()
                Text("As of 02:19")
            }

            HStack {
                Button("56") {
                    print("Order button pressed")
                }

                VStack {
                    HStack {
                        Text("112")
                        /// Image
                    }

                    HStack {
                        Text("50")
                        // Image
                    }
                }
            }
        }
        .padding()
        .task {
            await viewModel.fetchStats()
        }
    }
}

#Preview {
    MyStoreView(dependencies: .fake())
}
