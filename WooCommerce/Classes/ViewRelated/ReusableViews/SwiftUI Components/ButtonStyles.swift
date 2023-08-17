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
    /// Defines if the content should be hidden.
    /// Useful for when we want to show an overlay on top of the bottom without hiding its decoration. Like showing a progress view.
    ///
    private(set) var hideContent = false

    var labelFont: Font = .headline
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButton(configuration: configuration, labelFont: labelFont, hideContent: hideContent)
    }
}

/// Adds a secondary button style while showing a progress view on top of the button when required.
///
struct SecondaryLoadingButtonStyle: PrimitiveButtonStyle {

    /// Set it to true to show a progress view within the button.
    ///
    let isLoading: Bool

    /// Optional text when the button is in loading state
    var loadingText: String?

    /// Returns a `ProgressView` if the view is loading.
    ///
    @ViewBuilder
    private var progressViewOverlay: some View {
        HStack(spacing: 8) {
            ProgressView()
            loadingText.map(Text.init)
                .secondaryBodyStyle()
        }
        .renderedIf(isLoading)
    }

    func makeBody(configuration: Configuration) -> some View {
        /// Only send trigger if the view is not loading.
        ///
        return Button(configuration)
            .buttonStyle(SecondaryButtonStyle(hideContent: isLoading))
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

/// A selectable button with border style similar to secondary button style with differences on the colors and a selected state.
struct SelectableSecondaryButtonStyle: ButtonStyle {
    /// Whether the button is selected.
    let isSelected: Bool
    let labelFont: Font

    init(isSelected: Bool, labelFont: Font = .body) {
        self.isSelected = isSelected
        self.labelFont = labelFont
    }

    func makeBody(configuration: Configuration) -> some View {
        SelectableSecondaryButton(isSelected: isSelected, configuration: configuration, labelFont: labelFont)
    }
}

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LinkButton(configuration: configuration)
    }
}

/// Button that looks like text without the default padding and size assumption.
struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TextButton(configuration: configuration)
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
    let labelFont: Font

    /// Defines if the content should be hidden.
    /// Useful for when we want to show an overlay on top of the bottom without hiding its decoration. Like showing a progress view.
    ///
    private(set) var hideContent = false

    var body: some View {
        BaseButton(configuration: configuration)
            .opacity(contentOpacity)
            .foregroundColor(Color(foregroundColor))
            .font(labelFont)
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

    var contentOpacity: Double {
        hideContent ? 0.0 : 1.0
    }
}

private struct SelectableSecondaryButton: View {
    @Environment(\.isEnabled) var isEnabled

    let isSelected: Bool
    let configuration: ButtonStyleConfiguration
    let labelFont: Font

    var body: some View {
        BaseButton(configuration: configuration)
            .foregroundColor(Color(.selectableSecondaryButtonTitle))
            .font(labelFont)
            .background(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .fill(Color(backgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Style.defaultCornerRadius)
                    .strokeBorder(
                        Color(borderColor),
                        lineWidth: isSelected ? Style.defaultSelectedBorderWidth: Style.defaultBorderWidth
                    )
            )
    }

    var foregroundColor: UIColor {
        isEnabled ? .secondaryButtonTitle : .buttonDisabledTitle
    }

    var backgroundColor: UIColor {
        if isEnabled {
            if configuration.isPressed || isSelected {
                return .selectableSecondaryButtonSelectedBackground
            } else {
                return .selectableSecondaryButtonBackground
            }
        } else {
            return .buttonDisabledBackground
        }
    }

    var borderColor: UIColor {
        if isEnabled {
            if configuration.isPressed || isSelected {
                return .selectableSecondaryButtonSelectedBorder
            } else {
                return .selectableSecondaryButtonBorder
            }
        } else {
            return .buttonDisabledBorder
        }
    }
}

private struct LinkButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    var body: some View {
        BaseButton(configuration: configuration)
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

private struct TextButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .contentShape(Rectangle())
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
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
    static let defaultSelectedBorderWidth = CGFloat(2.0)
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

            Button("Selectable secondary button (selected)") {}
                .buttonStyle(SelectableSecondaryButtonStyle(isSelected: true))

            Button("Selectable secondary button") {}
                .buttonStyle(SelectableSecondaryButtonStyle(isSelected: false))

            Button("Link button") {}
                .buttonStyle(LinkButtonStyle())

            Button("Link button (Disabled)") {}
            .buttonStyle(LinkButtonStyle())
            .disabled(true)

            Button("Plus button") {}
                .buttonStyle(PlusButtonStyle())

            Button("Plus button (disabled)") {}
            .buttonStyle(PlusButtonStyle())
            .disabled(true)
        }
        .preferredColorScheme(.light)
        .padding()

        VStack(spacing: 20) {
            Group {
                Button("Primary button") {}
                    .buttonStyle(PrimaryButtonStyle())

                Button("Primary button (disabled)") {}
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(true)
            }

            Group {
                Button("Secondary button") {}
                    .buttonStyle(SecondaryButtonStyle())

                Button("Secondary button (disabled)") {}
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(true)
            }

            Group {
                Button("Selectable secondary button (selected)") {}
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: true))

                Button("Selectable secondary button") {}
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: false))
            }

            Group {
                Button("Link button") {}
                    .buttonStyle(LinkButtonStyle())

                Button("Link button (Disabled)") {}
                    .buttonStyle(LinkButtonStyle())
                    .disabled(true)
            }

            Group {
                Button("Text button") {}
                    .buttonStyle(TextButtonStyle())

                Button("Text button (disabled)") {}
                    .buttonStyle(TextButtonStyle())
                    .disabled(true)
            }

            Group {
                Button("Plus button") {}
                    .buttonStyle(PlusButtonStyle())

                Button("Plus button (disabled)") {}
                    .buttonStyle(PlusButtonStyle())
                    .disabled(true)
            }
        }
        .preferredColorScheme(.dark)
        .padding()
    }
}
