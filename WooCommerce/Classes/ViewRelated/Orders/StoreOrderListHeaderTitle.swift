import StoreDesignSystem
import SwiftUI

struct StoreOrderListHeaderTitle: View {
    let state: StoreOrderListHeaderState

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s1) {
            Text(state.title)
                .storeTextStyle(.titleMedium.strong)
            if let lastUpdatedText = state.lastUpdatedText {
                Text(lastUpdatedText)
                    .storeTextStyle(.bodySmall)
                    .foregroundStyle(Color.storeOnSurfaceVariant)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
