import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ObservedObject var viewModel: ItemListViewModel
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize

    init(viewModel: ItemListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            headerView
            switch viewModel.state {
            case .empty, .error:
                // These cases are handled directly in the dashboard, we do not render
                // a specific view within the ItemListView to handle them
                EmptyView()
            case .loading, .loaded:
                listView(viewModel.items)
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .background(Color.posPrimaryBackground)
        .accessibilityElement(children: .contain)
    }
}

/// View Helpers
///
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            HStack {
                POSHeaderTitleView()
                if !viewModel.shouldShowHeaderBanner {
                    Spacer()
                    Button(action: {
                        viewModel.simpleProductsInfoButtonTapped()
                    }, label: {
                        Image(systemName: "info.circle")
                            .font(.posTitleRegular)
                    })
                    .foregroundColor(.posPrimaryText)
                    .padding(.trailing, Constants.infoIconPadding)
                }
            }
            if viewModel.shouldShowHeaderBanner {
                bannerCardView
                    .padding(.bottom, Constants.bannerCardPadding)
            }
        }
    }

    var bannerCardView: some View {
        HStack(alignment: .top) {
            VStack {
                Spacer()
                Image(systemName: "info.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.bannerInfoIconSize, height: Constants.bannerInfoIconSize)
                    .padding(Constants.iconPadding)
                    .foregroundColor(Color(uiColor: .wooCommercePurple(.shade30)))
                    .accessibilityHidden(true)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Constants.bannerTitleSpacing) {
                Text(Localization.headerBannerTitle)
                    .font(Constants.bannerTitleFont)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Constants.bannerTextSpacing) {
                    Text(Localization.headerBannerSubtitle)
                    Text(Localization.headerBannerHint)
                    Text(Localization.headerBannerLearnMoreHint)
                        .linkStyle()
                }
                .font(Constants.bannerSubtitleFont)
                .accessibilityElement(children: .combine)
            }
            .padding(.vertical, Constants.bannerVerticalPadding)
            Spacer()
            VStack {
                Button(action: {
                    viewModel.dismissBanner()
                }, label: {
                    Image(systemName: "xmark")
                        .font(.posBodyRegular)
                        .foregroundColor(Color.posTertiaryText)
                        .accessibilityLabel(Localization.dismissBannerAccessibilityLabel)
                })
                .padding(Constants.iconPadding)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.posSecondaryBackground)
        .cornerRadius(Constants.bannerCornerRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            viewModel.simpleProductsInfoButtonTapped()
        }
        .padding(.horizontal, Constants.bannerCardPadding)
    }

    @ViewBuilder
    func listView(_ items: [POSItem]) -> some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.productID) { item in
                    Button(action: {
                        viewModel.select(item)
                    }, label: {
                        ItemCardView(item: item)
                    })
                }
            }
            .padding(.bottom, floatingControlAreaSize.height)
            .padding(.horizontal, Constants.itemListPadding)
        }
    }
}

/// Constants
///
private extension ItemListView {
    enum Constants {
        static let bannerTitleFont: POSFontStyle = .posBodyEmphasized
        static let bannerSubtitleFont: POSFontStyle = .posDetailRegular
        static let bannerCornerRadius: CGFloat = 8
        static let bannerVerticalPadding: CGFloat = 26
        static let bannerTextSpacing: CGFloat = 2
        static let bannerTitleSpacing: CGFloat = 8
        static let infoIconPadding: CGFloat = 16
        static let bannerInfoIconSize: CGFloat = 44
        static let iconPadding: CGFloat = 26
        static let itemListPadding: CGFloat = 16
        static let bannerCardPadding: CGFloat = 16
    }

    enum Localization {
        static let headerBannerTitle = NSLocalizedString(
            "pos.itemlistview.headerBanner.title",
            value: "Showing simple products only",
            comment: "Title of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerSubtitle = NSLocalizedString(
            "pos.itemlistview.headerBanner.subtitle",
            value: "Only simple physical products are available with POS right now.",
            comment: "Subtitle of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerHint = NSLocalizedString(
            "pos.itemlistview.headerBanner.hint",
            value: "Other product types, such as variable and virtual, will become available in future updates.",
            comment: "Additional text within the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerLearnMoreHint = NSLocalizedString(
            "pos.itemlistview.headerBanner.learnMoreHint",
            value: "Learn More",
            comment: "Link to more information within the product selector header banner, which explains current POS limitations"
        )

        static let dismissBannerAccessibilityLabel = NSLocalizedString(
            "pos.itemListView.headerBanner.dismiss.button.accessibiltyLabel",
            value: "Dismiss",
            comment: "Accessibility label for button to dismiss the product selector header banner. " +
            "The banner explains current POS limitations. Tapping the button prevents it being shown again."
        )
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: ItemListViewModel(itemProvider: POSItemProviderPreview()))
}
#endif
