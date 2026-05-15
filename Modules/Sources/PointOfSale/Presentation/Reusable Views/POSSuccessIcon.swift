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
        layoutScale == .phone ? Constants.phoneIconSize : Constants.tabletIconSize
    }

    private var checkmarkSize: CGFloat {
        layoutScale == .phone ? Constants.phoneCheckmarkSize : Constants.tabletCheckmarkSize
    }
}

private extension POSSuccessIcon {
    enum Constants {
        static let tabletIconSize: CGFloat = 165
        static let tabletCheckmarkSize: CGFloat = 64
        static let phoneIconSize: CGFloat = 72
        static let phoneCheckmarkSize: CGFloat = 28
    }
}

#if DEBUG
#Preview {
    POSSuccessIcon()
}
#endif
