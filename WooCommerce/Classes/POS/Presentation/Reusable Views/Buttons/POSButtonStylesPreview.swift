import SwiftUI

#if DEBUG

/// A preview that demonstrates all available POS button styles
struct POSButtonStylesPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            // Text Button
            Button("Text Button") {}
                .buttonStyle(POSTextButtonStyle())

            // Disabled state examples
            Group {
                Button("Disabled Text") {}
                    .buttonStyle(POSTextButtonStyle())
                    .disabled(true)
            }
        }
        .padding()
    }
}

#Preview {
    POSButtonStylesPreview()
}

#endif
