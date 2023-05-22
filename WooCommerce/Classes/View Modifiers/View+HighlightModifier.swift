import SwiftUI

/// Casts a blinking border highlight into any view given a Published `state` to control it's visibility
///
struct HighlightModifier: ViewModifier {
    let highlighted: Binding<Bool>
    let color: Color
    let repeatCount: Int
    let duration: Double

    private var animationActive: Binding<Bool> {
        Binding<Bool>(get: {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.duration) {
                self.highlighted.wrappedValue = false
            }
            return self.highlighted.wrappedValue
        }, set: {
            self.highlighted.wrappedValue = $0
        })
    }

    func body(content: Content) -> some View {
        content
            .border(self.animationActive.wrappedValue ? self.color : Color.clear, width: 3.0)
            .animation(Animation.linear(duration: self.duration).repeatCount(self.repeatCount),
                       value: animationActive.wrappedValue)
    }
}

// MARK: View extension
extension View {
    func highlight(on highlighted: Binding<Bool>, color: Color,
                     repeatCount: Int = 3, duration: Double = 0.5) -> some View {
        self.modifier(HighlightModifier(highlighted: highlighted,
                                        color: color,
                                        repeatCount: repeatCount,
                                        duration: duration))
    }
}
