import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
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
            case .loading:
                /// TODO: handle pull to refresh
                listView(viewModel.items)
            case .loaded(let items):
                listView(items)
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .padding(.horizontal, Constants.itemListPadding)
        .background(Color.posBackgroundGreyi3)
    }
}

/// View Helpers
///
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            HStack {
                headerTextView
                if !viewModel.shouldShowHeaderBanner {
                    Spacer()
                    Button(action: {
                        openInfoBanner()
                    }, label: {
                        Image(systemName: "info.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.infoIconSize, height: Constants.infoIconSize)
                            .foregroundColor(Color(uiColor: .wooCommercePurple(.shade50)))
                    })
                }
            }
            if viewModel.shouldShowHeaderBanner {
                bannerCardView
                    .padding(.vertical, 16)
            }
        }
    }

    private func openInfoBanner() {
        // TODO:
        // https://github.com/woocommerce/woocommerce-ios/issues/13357
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
                Spacer()
            }
            VStack(alignment: .leading) {
                Text(Localization.headerBannerTitle)
                    .font(Constants.bannerTitleFont)
                    .padding(.bottom, Constants.bannerTitleBottomPadding)
                Text(Localization.headerBannerSubtitle)
                    .font(Constants.bannerSubtitleFont)
                Text(Localization.headerBannerHint)
                    .font(Constants.bannerSubtitleFont)
            }
            .padding(.vertical, Constants.bannerVerticalPadding)
            Spacer()
            VStack {
                Button(action: {
                    viewModel.dismissBanner()
                }, label: {
                    Image(PointOfSaleAssets.dismissProductsBanner.imageName)
                        .frame(width: Constants.closeIconSize, height: Constants.closeIconSize)
                        .foregroundColor(Color.posTertiaryTexti3)
                })
                .padding(Constants.iconPadding)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.posBackgroundWhitei3)
        .cornerRadius(Constants.bannerCornerRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        .onTapGesture {
            openInfoBanner()
        }
    }

    var headerTextView: some View {
        Text(Localization.productSelectorTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Constants.headerPadding)
            .font(Constants.titleFont)
            .foregroundColor(Color.posPrimaryTexti3)
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
        }
    }
}

/// Constants
///
private extension ItemListView {
    enum Constants {
        static let titleFont: Font = .system(size: 40, weight: .bold, design: .default)
        static let bannerTitleFont: Font = .system(size: 24, weight: .bold, design: .default)
        static let bannerSubtitleFont: Font = .system(size: 16, weight: .medium, design: .default)
        static let bannerHeight: CGFloat = 164
        static let bannerCornerRadius: CGFloat = 8
        static let bannerVerticalPadding: CGFloat = 26
        static let bannerTitleBottomPadding: CGFloat = 16
        static let infoIconSize: CGFloat = 36
        static let bannerInfoIconSize: CGFloat = 44
        static let closeIconSize: CGFloat = 26
        static let iconPadding: CGFloat = 26
        static let headerPadding: CGFloat = 8
        static let itemListPadding: CGFloat = 16
    }

    enum Localization {
        static let productSelectorTitle = NSLocalizedString(
            "pos.itemlistview.productSelectorTitle",
            value: "Products",
            comment: "Title of the Point of Sale product selector"
        )
        static let headerBannerTitle = NSLocalizedString(
            "pos.itemlistview.headerBannerTitle",
            value: "Showing simple products only",
            comment: "Title of the product selector header banner, which explains current POS limitations"
        )
        static let headerBannerSubtitle = NSLocalizedString(
            "pos.itemlistview.headerBannerSubtitle",
            value: "Only simple physical products are available with POS right now.",
            comment: "Subtitle of the product selector header banner, which explains current POS limitations"
        )
        static let headerBannerHint = NSLocalizedString(
            "pos.itemlistview.headerBannerHint",
            value: "Other product types, such as variable and virtual, will become available in future updates. Learn more",
            comment: "Additional text within the product selector header banner, which explains current POS limitations"
        )
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: ItemListViewModel(itemProvider: POSItemProviderPreview()))
}
#endif
