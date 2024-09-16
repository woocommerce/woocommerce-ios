import SwiftUI

/// Hosting controller for `BlazeCreateCampaignIntroView`.
///
final class BlazeCreateCampaignIntroController: UIHostingController<BlazeCreateCampaignIntroView> {
    init(onCreateCampaign: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        super.init(rootView: BlazeCreateCampaignIntroView(onCreateCampaign: onCreateCampaign,
                                                          onDismiss: onDismiss))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to display the introduction to the Blaze campaign creation
///
struct BlazeCreateCampaignIntroView: View {
    @StateObject private var viewModel = BlazeCreateCampaignIntroViewModel()

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let onCreateCampaign: () -> Void
    private let onDismiss: () -> Void

    private let features: [Feature] = [.init(title: Localization.QuickStart.title, subtile: Localization.QuickStart.subtitle),
                                       .init(title: Localization.GlobalReach.title, subtile: Localization.GlobalReach.subtitle),
                                       .init(title: Localization.AudienceFeature.title, subtile: Localization.AudienceFeature.subtitle)]

    init(onCreateCampaign: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        self.onCreateCampaign = onCreateCampaign
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                onDismiss()
            }, label: {
                Image(uiImage: .closeButton)
                    .secondaryBodyStyle()
            })
            .padding(Layout.closeButtonPadding)

            ScrollView {
                VStack {
                    HStack(spacing: Layout.titleHSpacing) {
                        Image(uiImage: .blaze)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color(.accent))
                            .frame(width: Layout.logoSize * scale, height: Layout.logoSize * scale)

                        Text("Blaze")
                            .foregroundColor(Color(.accent))
                            .fontWeight(.semibold)
                            .headlineStyle()
                    }

                    VStack(spacing: Layout.titleElementsVerticalSpacing) {
                        Text(Localization.title)
                            .fontWeight(.bold)
                            .largeTitleStyle()
                            .multilineTextAlignment(.center)

                        Text(Localization.subtitle)
                            .secondaryBodyStyle()
                            .multilineTextAlignment(.center)

                        Image(uiImage: UIImage.blazeIntroIllustration)
                    }

                    VStack(spacing: Layout.featuresVerticalSpacing) {
                        ForEach(features, id: \.title) { feature in
                            FeatureView(feature: feature)
                        }
                    }
                }
                .padding(Layout.contentPadding)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Layout.CTAStack.spacing) {
                    Divider()
                        .frame(height: Layout.CTAStack.dividerHeight)
                        .foregroundColor(Color(.separator))

                    Button(Localization.createYourCampaign) {
                        onCreateCampaign()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Layout.CTAStack.buttonHPadding)

                    Button(Localization.learnHowBlazeWorks) {
                        viewModel.didTapLearnHowBlazeWorks()
                    }
                    .buttonStyle(LinkButtonStyle())
                    .padding(.horizontal, Layout.CTAStack.buttonHPadding)
                }
                .background(Color(UIColor.systemBackground))
            }
            .sheet(isPresented: $viewModel.showLearnHowSheet) {
                if #available(iOS 16, *) {
                    BlazeLearnHowView(isPresented: $viewModel.showLearnHowSheet)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.hidden)
                } else {
                    BlazeLearnHowView(isPresented: $viewModel.showLearnHowSheet)
                }
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

private extension BlazeCreateCampaignIntroView {
    struct Feature {
        let title: String
        let subtile: String
    }

    struct FeatureView: View {
        /// Scale of the view based on accessibility changes
        @ScaledMetric private var scale: CGFloat = 1.0

        let feature: Feature

        var body: some View {
            VStack(alignment: .leading) {

                Text(feature.title)
                    .fontWeight(.bold)
                    .bodyStyle()

                Text(feature.subtile)
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private extension BlazeCreateCampaignIntroView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeCreateCampaignIntroView.title",
            value: "Get your products seen by millions",
            comment: "Title for the Blaze campaign intro view"
        )
        static let subtitle = NSLocalizedString(
            "blazeCreateCampaignIntroView.subtitle",
            value: "Our tool is designed to empower merchants with fast, simple ad campaign setups for maximum traffic boost.",
            comment: "Subtitle for the Blaze campaign intro view"
        )
        static let createYourCampaign = NSLocalizedString(
            "blazeCreateCampaignIntroView.createYourCampaign",
            value: "Create Your Campaign",
            comment: "Create Your Campaign button label"
        )
        static let learnHowBlazeWorks = NSLocalizedString(
            "blazeCreateCampaignIntroView.learnHowBlazeWorks",
            value: "Learn how Blaze works",
            comment: "Learn how Blaze works button label"
        )
        enum QuickStart {
            static let title = NSLocalizedString(
                "blazeCreateCampaignIntroView.quickStart.title",
                value: "Quick start, big impact",
                comment: "Title for the quick start big impact feature"
            )
            static let subtitle = NSLocalizedString(
                "blazeCreateCampaignIntroView.quickStart.subtitle",
                value: "Launch ads in minutes – no experience or big budget needed, starting at just $5 USD daily.",
                comment: "Subtitle for the quick start big impact feature"
            )
        }
        enum GlobalReach {
            static let title = NSLocalizedString(
                "blazeCreateCampaignIntroView.globalReach.title",
                value: "Global reach made simple",
                comment: "Title for the Global reach feature"
            )
            static let subtitle = NSLocalizedString(
                "blazeCreateCampaignIntroView.globalReach.subtitle",
                value: "Our tool presents your product where interested shoppers can find it.",
                comment: "Subtitle for the Global reach feature"
            )
        }
        enum AudienceFeature {
            static let title = NSLocalizedString(
                "blazeCreateCampaignIntroView.audienceFeature.title",
                value: "Access a vast audience",
                comment: "Title for the access a vast audience feature"
            )
            static let subtitle = NSLocalizedString(
                "blazeCreateCampaignIntroView.audienceFeature.subtitle",
                value: "Your ads on millions of sites within the WordPress.com and Tumblr networks.",
                comment: "Subtitle for the access a vast audience feature"
            )
        }
    }
}

private enum Layout {
    static let closeButtonPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    static let contentPadding: EdgeInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24)
    static let titleElementsVerticalSpacing: CGFloat = 16
    static let featuresVerticalSpacing: CGFloat = 24

    static let titleHSpacing: CGFloat = 8
    static let logoSize: CGFloat = 19

    enum CTAStack {
        static let dividerHeight: CGFloat = 1
        static let spacing: CGFloat = 16
        static let buttonHPadding: CGFloat = 16
    }
}

struct BlazeCreateCampaignIntroView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCreateCampaignIntroView(onCreateCampaign: {},
                                     onDismiss: {})
    }
}
