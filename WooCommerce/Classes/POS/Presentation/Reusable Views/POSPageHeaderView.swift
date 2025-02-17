import SwiftUI

struct POSPageHeaderView<TrailingContent: View>: View {
    private let title: String
    private let subtitle: String?
    private let showBackButton: Bool
    private let trailingContent: TrailingContent?
    private let onBackTapped: (() -> Void)?

    private var showsBackButton: Bool {
        onBackTapped != nil
    }

    private var hStackAlignment: VerticalAlignment {
        subtitle == nil ? .center: .firstTextBaseline
    }

    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        onBackTapped: (() -> Void)? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.onBackTapped = onBackTapped
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack(alignment: hStackAlignment, spacing: Constants.horizontalSpacing) {
            if showsBackButton {
                Button(action: {
                    onBackTapped?()
                }, label: {
                    Text(Image(systemName: Constants.backButtonIcon))
                        .font(.posButtonSymbolLarge)
                        .foregroundColor(.posOnSurface)
                        .padding(.horizontal, Constants.backButtonHorizontalPadding)
                })
            }

            VStack(alignment: .leading, spacing: Constants.titleSubtitleSpacing) {
                Text(title)
                    .font(.posHeading)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                if let subtitle {
                    Text(subtitle)
                        .font(.posBodyLargeRegular())
                        .foregroundColor(.posOnSurfaceVariantHighest)
                }
            }

            Spacer()

            if let trailingContent {
                trailingContent
            }
        }
        .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
        .padding(.vertical, POSHeaderLayoutConstants.sectionVerticalPadding)
    }
}

private enum Constants {
    static let backButtonIcon = "chevron.backward"
    static let backButtonHorizontalPadding: CGFloat = 12
    static let horizontalSpacing: CGFloat = 16
    static let titleSubtitleSpacing: CGFloat = 4
}

#Preview {
    VStack(spacing: 20) {
        // Basic header with back button.
        POSPageHeaderView(
            title: "Products",
            onBackTapped: {}
        )

        // Header with subtitle.
        POSPageHeaderView(
            title: "Products",
            subtitle: "Select products to add to cart",
            onBackTapped: {}
        )

        // Header with trailing content.
        POSPageHeaderView(
            title: "Products",
            onBackTapped: {}
        ) {
            HStack(spacing: 16) {
                Button(action: {}) {
                    Text(Image(systemName: "info.circle"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)

                Button(action: {}) {
                    Text(Image(systemName: "trash"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            }
        }

        // Header with everything.
        POSPageHeaderView(
            title: "Products",
            subtitle: "Select products to add to cart",
            onBackTapped: {}
        ) {
            Button(action: {}) {
                Text(Image(systemName: "info.circle"))
                    .font(.posButtonSymbolLarge)
            }
            .foregroundColor(.posOnSurface)
        }

        // Header without back button.
        POSPageHeaderView(
            title: "Products",
            subtitle: "Select products to add to cart",
            trailingContent: {
                Button(action: {}) {
                    Text(Image(systemName: "info.circle"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            })
    }
    .background(Color.posSurface)
}
