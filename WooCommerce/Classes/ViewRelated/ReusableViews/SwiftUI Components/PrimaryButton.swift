import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }
}

private struct PrimaryButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: PrimaryButtonStyle.Configuration

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .font(.headline)
            .padding(Style.defaultEdgeInsets)
            .foregroundColor(Color(isEnabled ? .primaryButtonTitle : .buttonDisabledTitle))
            .background(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .fill(Color(isEnabled
                                        ? configuration.isPressed ? .primaryButtonDownBackground : .primaryButtonBackground
                                        : .buttonDisabledBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .strokeBorder(
                        Color(isEnabled
                                    ? configuration.isPressed ? .primaryButtonDownBorder : .primaryButtonBorder
                                    : .buttonDisabledBorder),
                        lineWidth: Style.defaultBorderWidth
                    )
            )
    }
}

private enum Style {
    static let defaultCornerRadius = CGFloat(8.0)
    static let defaultBorderWidth = CGFloat(1.0)
    static let defaultEdgeInsets = EdgeInsets(top: 12, leading: 22, bottom: 12, trailing: 22)
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Button("Test button") {
                print("test")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Test button") {
                print("test")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(true)
        }
    }
}
