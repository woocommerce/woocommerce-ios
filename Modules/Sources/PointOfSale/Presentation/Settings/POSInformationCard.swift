import SwiftUI

struct POSInformationCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
    }
}

struct POSInformationCardFieldRow: View {
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
    let isLoading: Bool

    init(label: String,
         value: String,
         showSeparator: Bool = true,
         labelStyle: LabelStyle = .regular,
         buttonTitle: String? = nil,
         buttonAction: (() -> Void)? = nil,
         buttonStyle: ButtonStyle = .default,
         isLoading: Bool = false) {
        self.label = label
        self.value = value
        self.showSeparator = showSeparator
        self.labelStyle = labelStyle
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.buttonStyle = buttonStyle
        self.isLoading = isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            HStack(alignment: .center, spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSPadding.small) {
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
                            isLoading: isLoading
                        ))
                }
            }

            if showSeparator {
                Divider()
                    .padding(.top, POSPadding.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
