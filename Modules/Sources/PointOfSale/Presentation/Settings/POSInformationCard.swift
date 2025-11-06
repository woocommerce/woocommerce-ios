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

    init(label: String, value: String, showSeparator: Bool = true) {
        self.label = label
        self.value = value
        self.showSeparator = showSeparator
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            Text(label)
                .font(.posBodyMediumRegular())
            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)

            if showSeparator {
                Divider()
                    .padding(.top, POSPadding.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSPadding.medium)
    }
}
