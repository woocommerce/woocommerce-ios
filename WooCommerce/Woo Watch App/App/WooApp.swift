import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @WKApplicationDelegateAdaptor var delegate: AppDelegate

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    @StateObject var appBindings = AppBindings()

    // Refactor: Include this variable into AppBindings
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
                .sheet(item: $appBindings.orderNotification, content: { orderNotification in
                    VStack {
                        Text("\(orderNotification.title)")
                        Text("\(orderNotification.subtitle ?? "")")
                        Text("\(orderNotification.message ?? "")")
                    }
                })
                .compatibleVerticalStyle()
                .environment(\.dependencies, dependencies)
                .task {
                    // For some reason I can't use the bindings directly from our AppDelegate.
                    // We need to store them in this type assign them to the delegate for further modification.
                    delegate.appBindings = appBindings
                }
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
