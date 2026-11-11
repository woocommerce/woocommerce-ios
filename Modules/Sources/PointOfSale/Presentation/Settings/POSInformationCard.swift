import SwiftUI

struct POSInformationCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .posPadding(\.medium)
            .frame(maxWidth: .infinity)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
    }
}

struct POSInformationCardFieldRow: View {
    @Environment(\.posMetrics) private var metrics
    enum ButtonStyle {
        case `default`
        case primary
    }

    enum LabelStyle {
        case regular
        case bold
    }

    let label: String
    let value: String
    let showSeparator: Bool
    let labelStyle: LabelStyle
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let buttonStyle: ButtonStyle
    let isButtonEnabled: Bool
    let buttonAccessibilityLabel: String?

    init(label: String,
         value: String,
         showSeparator: Bool = true,
         labelStyle: LabelStyle = .regular,
         buttonTitle: String? = nil,
         buttonAction: (() -> Void)? = nil,
         buttonStyle: ButtonStyle = .default,
         isButtonEnabled: Bool = true,
         buttonAccessibilityLabel: String? = nil) {
        self.label = label
        self.value = value
        self.showSeparator = showSeparator
        self.labelStyle = labelStyle
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.buttonStyle = buttonStyle
        self.isButtonEnabled = isButtonEnabled
        self.buttonAccessibilityLabel = buttonAccessibilityLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.padding.small) {
            HStack(alignment: .center, spacing: metrics.spacing.medium) {
                VStack(alignment: .leading, spacing: metrics.padding.small) {
                    Text(label)
                        .font(labelStyle == .bold ? .posBodyMediumBold : .posBodyMediumRegular())
                    Text(value)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let buttonTitle, let buttonAction {
                    Button(buttonTitle, action: buttonAction)
                        .buttonStyle(POSInfoCardButtonStyle(
                            size: .compact,
                            variant: buttonStyle == .primary ? .primary : .default,
                            isLoading: false
                        ))
                        .disabled(!isButtonEnabled)
                        .accessibilityLabel(buttonAccessibilityLabel ?? buttonTitle)
                }
            }

            if showSeparator {
                Divider()
                    .padding(.top, metrics.padding.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
