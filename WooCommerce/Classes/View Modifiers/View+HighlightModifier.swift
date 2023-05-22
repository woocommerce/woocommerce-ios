import SwiftUI

struct HighlightModifier: ViewModifier {
    let state: Binding<Bool>
    let color: Color
    let repeatCount: Int
    let duration: Double

    private var blinking: Binding<Bool> {
        Binding<Bool>(get: {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.duration) {
                self.state.wrappedValue = false
            }
            return self.state.wrappedValue }, set: {
            self.state.wrappedValue = $0
        })
    }

    func body(content: Content) -> some View {
        content
            .border(self.blinking.wrappedValue ? self.color : Color.clear, width: 3.0)
            .animation(Animation.linear(duration: self.duration).repeatCount(self.repeatCount),
                       value: blinking.wrappedValue)
    }
}

extension View {
    func highlight(on state: Binding<Bool>, color: Color,
                     repeatCount: Int = 3, duration: Double = 0.5) -> some View {
        self.modifier(HighlightModifier(state: state, color: color,
                                             repeatCount: repeatCount, duration: duration))
    }
}
