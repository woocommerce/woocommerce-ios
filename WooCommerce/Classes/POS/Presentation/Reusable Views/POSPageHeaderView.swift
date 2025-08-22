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
    let buttonIcon: String?

    init(state: State, action: @escaping () -> Void, buttonIcon: String? = nil) {
        self.state = state
        self.action = action
        self.buttonIcon = buttonIcon
    }
}

struct POSPageHeaderItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: (() -> Void)?

    init(title: String, subtitle: String? = nil, isSelected: Bool, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }
}

/// A header view for POS pages.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-450_24951
@available(iOS 17.0, *)
struct POSPageHeaderView<TrailingContent: View>: View {
    private let items: [POSPageHeaderItem]
    private let backButtonConfiguration: POSPageHeaderBackButtonConfiguration?
    private let trailingContent: TrailingContent?

    private var hStackAlignment: VerticalAlignment {
        items.first?.subtitle == nil ? .center: .firstTextBaseline
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
        self.items = [.init(title: title, subtitle: subtitle, isSelected: true)]
        self.backButtonConfiguration = backButtonConfiguration
        self.trailingContent = trailingContent()
    }

    init(
        items: [POSPageHeaderItem],
        backButtonConfiguration: POSPageHeaderBackButtonConfiguration? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.items = items
        self.backButtonConfiguration = backButtonConfiguration
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack(alignment: hStackAlignment, spacing: Constants.horizontalSpacing) {
            if showsBackButton {
                backButton
            }

            HStack(alignment: hStackAlignment, spacing: POSSpacing.large) {
                ForEach(0..<items.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: Constants.titleSubtitleSpacing) {
                        Button(action: {
                            items[index].action?()
                        }) {
                            Text(items[index].title)
                                .font(.posHeadingBold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                                .foregroundColor(items[index].isSelected ? .posOnSurface : .posOnSurfaceVariantLowest)
                        }
                        .disabled(items[index].isSelected)
                        .accessibilityElement()
                        .accessibilityAddTraits(items.count == 1 ? .isHeader : [.isHeader, .isButton])
                        .accessibilityLabel(items[index].title)

                        if let subtitle = items[index].subtitle {
                            Text(subtitle)
                                .font(.posBodyLargeRegular())
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                                .foregroundColor(.posOnSurface)
                        }
                    }
                }
            }

            if items.isNotEmpty {
                Spacer()
            }

            if let trailingContent {
                trailingContent
            }
        }
        .frame(minHeight: POSHeaderLayoutConstants.minHeight)
        .padding(.leading, shouldHaveLeadingPaddingForItems ? POSHeaderLayoutConstants.sectionHorizontalPadding : POSPadding.none)
        .padding(.trailing, POSHeaderLayoutConstants.sectionHorizontalPadding)
        .padding(.vertical, POSHeaderLayoutConstants.sectionVerticalPadding)
    }

    private var shouldHaveLeadingPaddingForItems: Bool {
        items.isNotEmpty  || showsBackButton
    }

    @ViewBuilder
    private var backButton: some View {
        if let configuration = backButtonConfiguration {
            POSPageHeaderBackButton(configuration: configuration)
        }
    }
}

private enum Constants {
    static let horizontalSpacing: CGFloat = POSSpacing.medium
    static let titleSubtitleSpacing: CGFloat = POSSpacing.xSmall
}



@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isProductsSelected: Bool = true

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

        // Header with two items and trailing content.
        POSPageHeaderView(
            items: [
                .init(title: "Products", isSelected: isProductsSelected) { isProductsSelected.toggle() },
                .init(title: "Coupons", isSelected: !isProductsSelected) { isProductsSelected.toggle() }
            ]
        ) {
            HStack(spacing: 16) {
                Button(action: {}) {
                    Text(Image(systemName: "plus"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)

                Button(action: {}) {
                    Text(Image(systemName: "magnifyingglass"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            }
        }
    }
    .background(Color.posSurface)
}
