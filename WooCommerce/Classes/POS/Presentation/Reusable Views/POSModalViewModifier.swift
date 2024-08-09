import SwiftUI

struct POSModalViewModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let modalContent: () -> ModalContent
    let fixedWidth: Bool
    let fixedHeight: Bool

    @Environment(\.sizeCategory) var sizeCategory

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isPresented ? 3 : 0)
                .disabled(isPresented)

            if isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                modalContent()
                    .frame(
                        width: fixedWidth ? min(frameWidth, windowBounds.width) : nil,
                        height: fixedHeight ? min(frameHeight, windowBounds.height) : nil)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .transition(.scale)
                    .zIndex(1)
                    .padding()
            }
        }
    }

    private var frameWidth: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            return 496
        case .large, .extraLarge:
            return 560
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 624
        case .accessibilityMedium,
                .accessibilityLarge,
                .accessibilityExtraLarge,
                .accessibilityExtraExtraLarge,
                .accessibilityExtraExtraExtraLarge:
            return windowBounds.width
        @unknown default:
            return 624
        }
    }

    private var frameHeight: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            return 528
        case .large, .extraLarge:
            return 592
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 640
        case .accessibilityMedium,
                .accessibilityLarge,
                .accessibilityExtraLarge,
                .accessibilityExtraExtraLarge,
                .accessibilityExtraExtraExtraLarge:
            return windowBounds.height
        @unknown default:
            return 640
        }
    }

    private var windowBounds: CGRect {
        window?.bounds ?? UIScreen.main.bounds
    }

    private var window: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
}

extension View {
    func posModal<ModalContent: View>(isPresented: Binding<Bool>,
                                      fixedWidth: Bool = true,
                                      fixedHeight: Bool = true,
                                      @ViewBuilder content: @escaping () -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifier(isPresented: isPresented,
                                 modalContent: content,
                                 fixedWidth: fixedWidth,
                                 fixedHeight: fixedHeight))
    }
}
