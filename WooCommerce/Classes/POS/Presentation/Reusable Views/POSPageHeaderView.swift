import SwiftUI

/// Configuration for the back button in the header.
struct POSPageHeaderBackButtonConfiguration {
    enum State {
        case enabled
        case shimmering
        case disabled
    }

    let state: State
    let action: () -> Void
}

/// A header view for POS pages.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-450_24951
struct POSPageHeaderView<TrailingContent: View>: View {
    private let title: String
    private let subtitle: String?
    private let backButtonConfiguration: POSPageHeaderBackButtonConfiguration?
    private let trailingContent: TrailingContent?

    private var hStackAlignment: VerticalAlignment {
        subtitle == nil ? .center: .firstTextBaseline
    }

    private var showsBackButton: Bool {
        backButtonConfiguration != nil
    }

    init(
        title: String,
        subtitle: String? = nil,
        backButtonConfiguration: POSPageHeaderBackButtonConfiguration? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backButtonConfiguration = backButtonConfiguration
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack(alignment: hStackAlignment, spacing: Constants.horizontalSpacing) {
            if showsBackButton {
                backButton
            }

            VStack(alignment: .leading, spacing: Constants.titleSubtitleSpacing) {
                Text(title)
                    .font(.posHeading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                if let subtitle {
                    Text(subtitle)
                        .font(.posBodyLargeRegular())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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

    @ViewBuilder
    private var backButton: some View {
        if let configuration = backButtonConfiguration {
            Button(action: configuration.action) {
                Text(Image(systemName: Constants.backButtonIcon))
                    .font(.posButtonSymbolLarge)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .foregroundColor(configuration.state == .disabled ? .posOnSurfaceVariantLowest : .posOnSurface)
                    .padding(.horizontal, Constants.backButtonHorizontalPadding)
            }
            .disabled(configuration.state == .disabled || configuration.state == .shimmering)
            .if(configuration.state == .shimmering) { view in
                view.shimmering()
            }
        }
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
        // Header without back button.
        POSPageHeaderView(
            title: "Products",
            trailingContent: {
                Button(action: {}) {
                    Text(Image(systemName: "info.circle"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            })

        // Basic header with back button.
        POSPageHeaderView(
            title: "Variation",
            backButtonConfiguration: .init(state: .enabled, action: {})
        )

        // Header with shimmering back button.
        POSPageHeaderView(
            title: "Cart",
            backButtonConfiguration: .init(state: .shimmering, action: {})
        )

        // Header with trailing content.
        POSPageHeaderView(
            title: "Products",
            backButtonConfiguration: .init(state: .enabled, action: {})
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

        // Header with subtitle.
        POSPageHeaderView(
            title: "Cash payment",
            subtitle: "Total: $100.00",
            backButtonConfiguration: .init(state: .enabled, action: {})
        )

        // Header with subtitle and disabled back button.
        POSPageHeaderView(
            title: "Cash payment",
            subtitle: "Total: $100.00",
            backButtonConfiguration: .init(state: .disabled, action: {})
        )

        // Header with everything.
        POSPageHeaderView(
            title: "Title",
            subtitle: "Subtitle",
            backButtonConfiguration: .init(state: .enabled, action: {})
        ) {
            Button(action: {}) {
                Text(Image(systemName: "info.circle"))
                    .font(.posButtonSymbolLarge)
            }
            .foregroundColor(.posOnSurface)
        }
    }
    .background(Color.posSurface)
}
