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

    let label: String
    let value: String
    let showSeparator: Bool
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let buttonStyle: ButtonStyle

    init(label: String,
         value: String,
         showSeparator: Bool = true,
         buttonTitle: String? = nil,
         buttonAction: (() -> Void)? = nil,
         buttonStyle: ButtonStyle = .default) {
        self.label = label
        self.value = value
        self.showSeparator = showSeparator
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.buttonStyle = buttonStyle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            HStack(alignment: .top, spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(label)
                        .font(.posBodyMediumRegular())
                    Text(value)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let buttonTitle, let buttonAction {
                    VStack {
                        Spacer()
                            .frame(height: POSPadding.xSmall)

                        Button(action: buttonAction) {
                            Text(buttonTitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(buttonStyle == .default ? Color.posOnSurface : Color.posOnPrimaryContainer)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, POSPadding.small)
                        .padding(.vertical, POSPadding.xSmall)
                        .background(buttonStyle == .primary ? Color.posPrimaryContainer : Color.posSurfaceContainerLowest)
                        .overlay {
                            RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value)
                                .stroke(buttonStyle == .default ? Color.posOnSurface : Color.posPrimaryContainer, lineWidth: 2)
                        }

                        Spacer()
                            .frame(height: POSPadding.xSmall)
                    }
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
