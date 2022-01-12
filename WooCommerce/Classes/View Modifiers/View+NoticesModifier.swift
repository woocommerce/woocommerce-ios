import SwiftUI
import Lottie

/// View Modifier to show a notice in front of a view.
///
struct NoticeModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content

            Text("Holi")
        }
    }
}

// MARK: View Extension

extension View {
    /// Shows a notice in front of the view.
    ///
    func notice() -> some View {
        self.modifier(NoticeModifier())
    }
}

// MARK: Preview

struct NoticeModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .notice()
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light Content")
    }
}
