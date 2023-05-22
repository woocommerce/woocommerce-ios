import SwiftUI

/// Casts a blinking border highlight into any view given a Published `state` to control it's visibility
///
struct HighlightModifier: ViewModifier {
    let highlighted: Binding<Bool>
    let color: Color

    private var animationActive: Binding<Bool> {
        Binding<Bool>(get: {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.highlightBlinkDuration) {
                self.highlighted.wrappedValue = false
            }
            return self.highlighted.wrappedValue
        }, set: {
            self.highlighted.wrappedValue = $0
        })
    }

    private var animation: Animation {
        Animation.linear(duration: Constants.highlightBlinkDuration)
            .repeatCount(Constants.highlightBlinkRepetition)
    }

    func body(content: Content) -> some View {
        content
            .border(animationActive.wrappedValue ? color : Color.clear,
                    width: Constants.highlightBorderWidth)
            .animation(animation, value: animationActive.wrappedValue)
    }
}

// MARK: View extension
extension View {
    func highlight(on highlighted: Binding<Bool>, color: Color) -> some View {
        self.modifier(HighlightModifier(highlighted: highlighted, color: color))
    }
}

private extension HighlightModifier {
    enum Constants {
        static let highlightBlinkDuration = 0.5
        static let highlightBlinkRepetition = 3
        static let highlightBorderWidth = 3.0
    }
}
