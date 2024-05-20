import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    var body: some Scene {
        WindowGroup {
            if let dependencies = phoneDependencySynchronizer.dependencies {
                TabView {
                    MyStoreView(dependencies: dependencies)
                    OrdersListView()
                }
                .compatibleVerticalStyle()
                .environment(\.dependencies, dependencies)
            } else {
                ConnectView()
            }
        }
    }
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
