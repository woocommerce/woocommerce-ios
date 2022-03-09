import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    /// Defines if the content should be hidden.
    /// Useful for when we want to show an overlay on top of the bottom without hiding its decoration. Like showing a progress view.
    ///
    private(set) var hideContent = false

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration, hideContent: hideContent)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButton(configuration: configuration)
    }
}

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LinkButton(configuration: configuration)
    }
}

struct PlusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        return PlusButton(configuration: configuration)
    }
}

/// Adds a primary button style while showing a progress view on top of the button when required.
///
struct PrimaryLoadingButtonStyle: PrimitiveButtonStyle {

    /// Set it to true to show a progress view within the button.
    ///
    let isLoading: Bool

    /// Returns a `ProgressView` if the view is loading. Return nil otherwise
    ///
    private var progressViewOverlay: ProgressView<EmptyView, EmptyView>? {
        isLoading ? ProgressView() : nil
    }

    func makeBody(configuration: Configuration) -> some View {
        /// Only send trigger if the view is not loading.
        ///
        return Button(configuration)
            .buttonStyle(PrimaryButtonStyle(hideContent: isLoading))
            .onTapGesture { dispatchTrigger(configuration) }
            .disabled(isLoading)
            .overlay(progressViewOverlay)
    }

    /// Only dispatch events while the view is not loading.
    ///
    private func dispatchTrigger(_ configuration: Configuration) {
        guard !isLoading else { return }
        configuration.trigger()
    }
}

private struct BaseButton: View {
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(Style.defaultEdgeInsets)
    }
}

private struct PrimaryButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    /// Defines if the content should be hidden.
    /// Useful for when we want to show an overlay on top of the bottom without hiding its decoration. Like showing a progress view.
    ///
    private(set) var hideContent = false

    var body: some View {
        BaseButton(configuration: configuration)
            .opacity(contentOpacity)
            .foregroundColor(Color(foregroundColor))
            .font(.headline)
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

    var contentOpacity: Double {
        hideContent ? 0.0 : 1.0
    }
}

private struct SecondaryButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    var body: some View {
        BaseButton(configuration: configuration)
            .foregroundColor(Color(foregroundColor))
            .font(.headline)
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

private struct LinkButton: View {
    let configuration: ButtonStyleConfiguration

    var body: some View {
        BaseButton(configuration: configuration)
            .foregroundColor(Color(foregroundColor))
            .background(Color(.clear))
    }

    var foregroundColor: UIColor {
        configuration.isPressed ? .accentDark : .accent
    }
}

private struct PlusButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    var body: some View {
        HStack {
            Label {
                configuration.label
            } icon: {
                Image(uiImage: .plusImage)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(Color(foregroundColor))
        .background(Color(.clear))
    }

    var foregroundColor: UIColor {
        if isEnabled {
            return configuration.isPressed ? .accentDark : .accent
        } else {
            return .buttonDisabledTitle
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

            Button("Link button") {}
                .buttonStyle(LinkButtonStyle())

            Button("Plus button") {}
                .buttonStyle(PlusButtonStyle())

            Button("Plus button (disabled)") {}
            .buttonStyle(PlusButtonStyle())
            .disabled(true)
        }
        .padding()
    }
}
