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
    let label: String
    let value: String
    let showSeparator: Bool
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    init(label: String,
         value: String,
         showSeparator: Bool = true,
         buttonTitle: String? = nil,
         buttonAction: (() -> Void)? = nil) {
        self.label = label
        self.value = value
        self.showSeparator = showSeparator
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
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
                                .foregroundStyle(Color.posOnSurface)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, POSPadding.small)
                        .padding(.vertical, POSPadding.xSmall)
                        .background(Color.posSurfaceContainerLowest)
                        .overlay {
                            RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value)
                                .stroke(Color.posOnSurface, lineWidth: 2)
                        }

                        Spacer()
                            .frame(height: POSPadding.xSmall)
                    }
                }
            }

            if showSeparator {
                Divider()
                    .padding(.top, POSPadding.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSPadding.medium)
    }
}
