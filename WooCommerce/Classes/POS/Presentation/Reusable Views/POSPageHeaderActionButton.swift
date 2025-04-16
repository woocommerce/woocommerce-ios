import SwiftUI

struct POSPageHeaderActionButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(.posSurfaceContainerLow)
                .overlay {
                    Image(systemName: systemName)
                        .font(.posButtonSymbolSmall)
                        .foregroundColor(.posOnSurface)
                }
                .frame(width: POSHeaderLayoutConstants.minHeight, height: POSHeaderLayoutConstants.minHeight)
        }
        .fixedSize()
    }
}
