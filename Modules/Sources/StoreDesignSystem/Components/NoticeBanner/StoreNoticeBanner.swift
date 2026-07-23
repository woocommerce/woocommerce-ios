import SwiftUI

public struct StoreNoticeBanner: View {
    private let title: String
    private let description: String?
    private let tone: StoreNoticeBannerTone
    private let icon: StoreIconImage?

    public init(_ title: String,
                description: String? = nil,
                tone: StoreNoticeBannerTone = .neutral,
                icon: StoreIconImage? = nil) {
        self.title = title
        self.description = description
        self.tone = tone
        self.icon = icon
    }

    public var body: some View {
        HStack(alignment: .center, spacing: StoreSpacing.s4) {
            icon?.image(size: .large)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                Text(title).storeTextStyle(.bodyMedium.emphasized)
                if let description {
                    Text(description).storeTextStyle(.bodyMedium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(StorePadding.p6)
        .foregroundStyle(tone.appearance.foreground)
        .background(tone.appearance.background ?? .clear)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.large))
        .overlay {
            if let border = tone.appearance.border {
                RoundedRectangle(cornerRadius: StoreRadius.large)
                    .strokeBorder(border, lineWidth: StoreStrokeWidth.regular)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
