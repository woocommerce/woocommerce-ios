import SwiftUI

/// Reads the safe-area insets of the container this view is laid out in and hands them to `content`.
/// Place it at a screen root, outside any `ScrollView`: inside scroll content there is no safe area left to read.
///
struct SafeAreaInsetsReader<Content: View>: View {
    @ViewBuilder let content: (EdgeInsets) -> Content

    @Environment(\.navigationColumnEdgesInsideSafeArea) private var navigationColumnEdgesInsideSafeArea

    var body: some View {
        GeometryReader { geometry in
            content(geometry.safeAreaInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.container, edges: navigationColumnEdgesInsideSafeArea)
    }
}

/// Horizontal edges of the enclosing navigation column that do not touch the window's unsafe area.
///
/// `NavigationStack` applies the window's horizontal insets to every screen in the stack even when its column
/// is clear of that edge (seen in the iPhone Duo open pose). A side-by-side container sets this so
/// `SafeAreaInsetsReader` can ignore those edges and report the column's real insets.
///
private struct NavigationColumnEdgesInsideSafeAreaKey: EnvironmentKey {
    static let defaultValue: Edge.Set = []
}

extension EnvironmentValues {
    var navigationColumnEdgesInsideSafeArea: Edge.Set {
        get { self[NavigationColumnEdgesInsideSafeAreaKey.self] }
        set { self[NavigationColumnEdgesInsideSafeAreaKey.self] = newValue }
    }
}
