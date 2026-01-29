import SwiftUI

struct FeatureAnnouncementCardView: View {
    private let viewModel: AnnouncementCardViewModelProtocol
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let dismiss: (() -> Void)?
    let callToAction: (() -> Void)?

    init(viewModel: AnnouncementCardViewModelProtocol,
         dismiss: (() -> Void)? = nil,
         callToAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.dismiss = dismiss
        self.callToAction = callToAction
    }

    var body: some View {
        if viewModel.showDividers {
            content
                .addingTopAndBottomDividers()
        } else {
            content
        }
    }

    var content: some View {
        VStack(alignment: .leading, spacing: Layout.smallSpacing) {
            if let badgeType = viewModel.badgeType {
                HStack(spacing: 0) {
                    BadgeView(type: badgeType)
                    Spacer()
                }
            }
            Text(viewModel.title)
                .headlineStyle()
                .padding(.trailing, viewModel.badgeType == nil ? Layout.titleTrailingNoBadgeCloseButtonPadding : Layout.padding)
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.message)
                        .bodyStyle()
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if let buttonTitle = viewModel.buttonTitle {
                        Button(buttonTitle) {
                            viewModel.ctaTapped()
                            callToAction?()
                        }
                        .buttonStyle(TextButtonStyle())
                    }
                }
                .padding(.bottom, Layout.padding)

                Spacer()

                if !dynamicTypeSize.isAccessibilitySize {
                    cornerImage
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if let dismiss = dismiss {
                Menu {
                    Button(Localization.hideContent) {
                        viewModel.dontShowAgainTapped()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, Layout.padding)
                        .padding(.vertical, Layout.hideIconVerticalPadding)
                }
                .padding(.trailing, Layout.padding)
            }
        }
        .padding(.top, Layout.padding)
        .padding(.leading, Layout.padding)
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder var cornerImage: some View {
        if let imageUrl = viewModel.imageUrl {
            AdaptiveAsyncImage(anyAppearanceUrl: imageUrl, darkUrl: viewModel.imageDarkUrl, scale: 3) { imagePhase in
                switch imagePhase {
                case .failure:
                    Image(uiImage: viewModel.image)
                        .accessibilityHidden(true)
                case .success(let image):
                    image.resizable()
                        .scaledToFit()
                        .accessibilityHidden(true)
                case .empty:
                    AnimatedPlaceholder()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(uiImage: viewModel.image)
                .accessibilityHidden(true)
        }
    }
}

extension FeatureAnnouncementCardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
        static let titleTrailingNoBadgeCloseButtonPadding: CGFloat = 48
        static let hideIconVerticalPadding: CGFloat = 8
    }
}

extension FeatureAnnouncementCardView {
    enum Localization {
        static let hideContent = NSLocalizedString(
            "featureAnnouncementCardView.hideContent",
            value: "Hide this content",
            comment: "This text appears as a menu item in a feature announcement card that allows users to dismiss or hide the entire announcement card from view. It's likely displayed in a context menu or as part of a dismissal action for promotional content or new feature notifications.")
    }
}
