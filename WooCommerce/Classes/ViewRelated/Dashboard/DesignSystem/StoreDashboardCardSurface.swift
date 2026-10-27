import StoreDesignSystem
import SwiftUI

struct StoreDashboardCardSurface<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.storeSurfaceBright)
            .clipShape(.rect(cornerRadius: StoreRadius.extraLarge))
    }
}
