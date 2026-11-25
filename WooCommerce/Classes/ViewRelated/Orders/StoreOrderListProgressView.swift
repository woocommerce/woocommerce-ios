import StoreDesignSystem
import SwiftUI

struct StoreOrderListProgressView: View {
    let isAnimating: Bool

    var body: some View {
        Group {
            if isAnimating {
                ProgressView()
                    .tint(.storePrimary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: StoreSize.minimumTapTarget)
        .background(.storeSurface)
    }
}
