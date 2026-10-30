import StoreDesignSystem
import SwiftUI

struct StoreDashboardSheetHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s5) {
            Text(title)
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(.storeOnSurface)
            Text(description)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurfaceVariant)
        }
    }
}
