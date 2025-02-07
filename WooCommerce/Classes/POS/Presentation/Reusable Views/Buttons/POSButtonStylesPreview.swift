import SwiftUI

#if DEBUG

/// A preview that demonstrates all available POS button styles
struct POSButtonStylesPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            // Primary Button
            Button("Primary Button") {}
                .buttonStyle(POSPrimaryButtonStyle())

            // Secondary Button
            Button("Secondary Button") {}
                .buttonStyle(POSSecondaryButtonStyle())

            // Tertiary Button
            Button("Tertiary Button") {}
                .buttonStyle(POSTertiaryButtonStyle())

            // Text Button
            Button("Text Button") {}
                .buttonStyle(POSTextButtonStyle())

            // Disabled state examples
            Group {
                Button("Disabled Primary") {}
                    .buttonStyle(POSPrimaryButtonStyle())
                    .disabled(true)
                Button("Disabled Secondary") {}
                    .buttonStyle(POSSecondaryButtonStyle())
                    .disabled(true)

                Button("Disabled Tertiary") {}
                    .buttonStyle(POSTertiaryButtonStyle())
                    .disabled(true)

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
