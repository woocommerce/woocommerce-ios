import SwiftUI
import struct Yosemite.BlazeCampaign
import struct Yosemite.Product
import Kingfisher

/// Hosting controller for `BlazeCampaignDashboardView`.
///
final class BlazeCampaignDashboardViewHostingController: SelfSizingHostingController<BlazeCampaignDashboardView> {
    private let viewModel: BlazeCampaignDashboardViewModel

    init(viewModel: BlazeCampaignDashboardViewModel) {
        self.viewModel = viewModel
        super.init(rootView: BlazeCampaignDashboardView(viewModel: viewModel))
        if #unavailable(iOS 16.0) {
            viewModel.onStateChange = { [weak self] in
                self?.view.invalidateIntrinsicContentSize()
            }
        }

        // TODO: Assign callback handlers and handle navigation
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        Task { @MainActor in
            await viewModel.reload(fetchFromRemote: false)
        }
    }
}

/// Blaze campaigns in dashboard screen.
struct BlazeCampaignDashboardView: View {
    /// Set externally in the hosting controller.
    var campaignTapped: (() -> Void)?

    /// Set externally in the hosting controller.
    var productTapped: (() -> Void)?

    /// Set externally in the hosting controller.
    var showAllCampaignsTapped: (() -> Void)?

    /// Set externally in the hosting controller.
    var createCampaignTapped: (() -> Void)?

    @ObservedObject private var viewModel: BlazeCampaignDashboardViewModel

    init(viewModel: BlazeCampaignDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            VStack(alignment: .leading, spacing: Layout.HeadingBlock.verticalSpacing) {
                // Title
                Text(Localization.title)
                    .fontWeight(.semibold)
                    .bodyStyle()

                // Subtitle
                Text(Localization.subtitle)
                    .fontWeight(.regular)
                    .subheadlineStyle()
                    .renderedIf(!viewModel.shouldShowShowAllCampaignsButton)
            }
            .redacted(reason: viewModel.shouldRedactView ? .placeholder : [])

            if case .showProduct(let product) = viewModel.state {
                ProductInfoView(product: product)
                    .onTapGesture {
                        productTapped?()
                    }
            } else if case .showCampaign(let campaign) = viewModel.state {
                BlazeCampaignItemView(campaign: campaign, showBudget: false)
                    .onTapGesture {
                        campaignTapped?()
                    }
            }

            // Show All Campaigns button
            showAllCampaignsButton
                .renderedIf(viewModel.shouldShowShowAllCampaignsButton)

            Divider()

            // Create campaign button
            createCampaignButton
                .redacted(reason: viewModel.shouldRedactView ? .placeholder : [])
        }
        .padding(insets: Layout.insets)
        .background(Color(uiColor: .listForeground(modal: false)))
    }
}

private extension BlazeCampaignDashboardView {
    var createCampaignButton: some View {
        Button {
            createCampaignTapped?()
        } label: {
            Text(Localization.createCampaign)
                .fontWeight(.semibold)
                .foregroundColor(.init(uiColor: .accent))
                .bodyStyle()
        }
    }

    var showAllCampaignsButton: some View {
        Button {
            showAllCampaignsTapped?()
        } label: {
            HStack {
                Text(Localization.showAllCampaigns)
                    .fontWeight(.regular)
                    .bodyStyle()

                Spacer()

                // Chevron icon
                Image(uiImage: .chevronImage)
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundColor(Color(.textTertiary))
            }
            .padding(insets: Layout.insets)
            .background(Color(uiColor: .init(light: UIColor.systemGray6,
                                             dark: UIColor.systemGray5)))
            .cornerRadius(Layout.cornerRadius)
        }
    }
}

private extension BlazeCampaignDashboardView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        enum HeadingBlock {
            static let verticalSpacing: CGFloat = 8
        }
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "🔥 Blaze campaign",
            comment: "Title of the Blaze campaign view."
        )

        static let subtitle = NSLocalizedString(
            "Increase visibility and get your products sold quickly.",
            comment: "Subtitle of the Blaze campaign view."
        )

        static let showAllCampaigns = NSLocalizedString(
            "Show All Campaigns",
            comment: "Button when tapped will show the Blaze campaign list."
        )

        static let createCampaign = NSLocalizedString(
            "Create campaign",
            comment: "Button when tapped will launch create Blaze campaign flow."
        )
    }
}

private struct ProductInfoView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let product: Product

    init(product: Product) {
        self.product = product
    }

    var body: some View {
        HStack(alignment: .center, spacing: Layout.contentSpacing) {
            KFImage(product.imageURL)
                .placeholder {
                    Image(uiImage: .productPlaceholderImage)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                .cornerRadius(Layout.cornerRadius)

            Text(product.name)
                .fontWeight(.semibold)
                .foregroundColor(.init(UIColor.text))
                .subheadlineStyle()
                .multilineTextAlignment(.leading)
                // This size modifier is necessary so that the product name is never truncated.
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Chevron icon
            Image(uiImage: .chevronImage)
                .flipsForRightToLeftLayoutDirection(true)
                .foregroundColor(Color(.textTertiary))
        }
        .padding(Layout.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
        }
    }

    private enum Layout {
        static let imageSize: CGFloat = 44
        static let contentSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let strokeWidth: CGFloat = 0.5
        static let cornerRadius: CGFloat = 8
    }
}


struct BlazeCampaignDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignDashboardView(viewModel: .init(siteID: 0))
    }
}
