import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    @State private var selectedTab = WooWatchTab.myStore

    var body: some Scene {
        WindowGroup {
            if let dependencies = phoneDependencySynchronizer.dependencies {
                TabView(selection: $selectedTab) {
                    MyStoreView(dependencies: dependencies, watchTab: $selectedTab)
                        .tag(WooWatchTab.myStore)

                    OrdersListView(dependencies: dependencies, watchTab: $selectedTab)
                        .tag(WooWatchTab.ordersList)
                }
                .compatibleVerticalStyle()
                .environment(\.dependencies, dependencies)
            } else {
                ConnectView()
            }
        }
    }
}

enum WooWatchTab: Int {
    case myStore
    case ordersList
}

/// Backwards compatible vertical `tabViewStyle` modifier.
///
private struct VerticalPageModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(watchOS 10.0, *) {
            content
                .tabViewStyle(.verticalPage)
        } else {
            content
                .tabViewStyle(.carousel)
        }
    }
}

private extension View {
    func compatibleVerticalStyle() -> some View {
        self.modifier(VerticalPageModifier())
    }
}
