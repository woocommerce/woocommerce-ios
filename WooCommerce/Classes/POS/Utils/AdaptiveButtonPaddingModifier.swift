import SwiftUI

struct AdaptiveButtonPaddingModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let defaultButtonPadding: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(adjustablePadding(for: dynamicTypeSize,
                                       defaultButtonPadding: defaultButtonPadding))
    }
    
    private func adjustablePadding(for size: DynamicTypeSize, defaultButtonPadding: CGFloat) -> CGFloat {
        switch size {
        case .xxxLarge:       return defaultButtonPadding * 0.7
        case .xxLarge:        return defaultButtonPadding * 0.8
        case .xLarge:         return defaultButtonPadding * 0.9
        case .accessibility1: return defaultButtonPadding * 0.6
        case .accessibility2: return defaultButtonPadding * 0.5
        case .accessibility3: return defaultButtonPadding * 0.4
        case .accessibility4: return defaultButtonPadding * 0.3
        case .accessibility5: return defaultButtonPadding * 0.2
        default:
            return defaultButtonPadding
        }
    }
}

extension View {
    func adaptiveButtonPadding(_ defaultButtonPadding: CGFloat) -> some View {
        modifier(AdaptiveButtonPaddingModifier(defaultButtonPadding: defaultButtonPadding))
    }
}
