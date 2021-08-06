import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButton(configuration: configuration)
    }
}

private struct BaseButton: View {
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .font(.headline)
            .padding(Style.defaultEdgeInsets)
    }
}

private struct PrimaryButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    var body: some View {
        BaseButton(configuration: configuration)
            .foregroundColor(Color(foregroundColor))
            .background(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .fill(Color(backgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .strokeBorder(
                        Color(borderColor),
                        lineWidth: Style.defaultBorderWidth
                    )
            )
    }

    var foregroundColor: UIColor {
        isEnabled ? .primaryButtonTitle : .buttonDisabledTitle
    }

    var backgroundColor: UIColor {
        if isEnabled {
            if configuration.isPressed {
                return .primaryButtonDownBackground
            } else {
                return .primaryButtonBackground
            }
        } else {
            return .buttonDisabledBackground
        }
    }

    var borderColor: UIColor {
        if isEnabled {
            if configuration.isPressed {
                return .primaryButtonDownBorder
            } else {
                return .primaryButtonBorder
            }
        } else {
            return .buttonDisabledBorder
        }
    }
}

private struct SecondaryButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    var body: some View {
        BaseButton(configuration: configuration)
            .foregroundColor(Color(foregroundColor))
            .background(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .fill(Color(backgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .strokeBorder(
                        Color(borderColor),
                        lineWidth: Style.defaultBorderWidth
                    )
            )
    }

    var foregroundColor: UIColor {
        isEnabled ? .secondaryButtonTitle : .buttonDisabledTitle
    }

    var backgroundColor: UIColor {
        if isEnabled {
            if configuration.isPressed {
                return .secondaryButtonDownBackground
            } else {
                return .secondaryButtonBackground
            }
        } else {
            return .buttonDisabledBackground
        }
    }

    var borderColor: UIColor {
        if isEnabled {
            if configuration.isPressed {
                return .secondaryButtonDownBorder
            } else {
                return .secondaryButtonBorder
            }
        } else {
            return .buttonDisabledBorder
        }
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
            Button("Primary button") {}
                .buttonStyle(PrimaryButtonStyle())

            Button("Primary button (disabled)") {}
                .buttonStyle(PrimaryButtonStyle())
                .disabled(true)

            Button("Secondary button") {}
                .buttonStyle(SecondaryButtonStyle())

            Button("Secondary button (disabled)") {}
                .buttonStyle(SecondaryButtonStyle())
                .disabled(true)
        }
        .padding()
    }
}
