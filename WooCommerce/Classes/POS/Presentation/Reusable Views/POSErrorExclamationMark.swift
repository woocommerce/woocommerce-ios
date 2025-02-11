import SwiftUI

struct POSErrorExclamationMark: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Text(Image(systemName: "exclamationmark.circle.fill"))
            .font(.posButtonSymbolLarge)
            .foregroundStyle(Color.posAlert)
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorExclamationMark()
}
