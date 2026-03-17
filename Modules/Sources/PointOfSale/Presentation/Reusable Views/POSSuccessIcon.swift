import SwiftUI

struct POSSuccessIcon: View {
    @Environment(\.posLayoutScale) private var layoutScale

    var body: some View {
        ZStack {
            Circle()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.posSuccess)
            Image(systemName: "checkmark")
                .font(.system(size: checkmarkSize, weight: .bold))
                .foregroundColor(.posOnSuccess)
                .accessibilityHidden(true)
        }
    }

    private var iconSize: CGFloat {
        layoutScale == .phone ? 72 : 165
    }

    private var checkmarkSize: CGFloat {
        layoutScale == .phone ? 28 : 64
    }
}

#if DEBUG
#Preview {
    POSSuccessIcon()
}
#endif
