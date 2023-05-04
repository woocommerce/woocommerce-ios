import SwiftUI
import WordPressUI // For GhostStyle defaults

struct FeatureAnnouncementCardView: View {
    private let viewModel: AnnouncementCardViewModelProtocol
    @State private var showingDismissActionSheet = false

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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                BadgeView(type: viewModel.badgeType)
                    .padding(.leading, Layout.padding)
                Spacer()
                if let dismiss = dismiss {
                    Button(action: {
                        if viewModel.showDismissConfirmation {
                            showingDismissActionSheet = true
                        } else {
                            viewModel.dontShowAgainTapped()
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(.withColorStudio(.gray)))
                    }
                    .padding(.trailing, Layout.padding)
                    .actionSheet(isPresented: $showingDismissActionSheet) {
                        ActionSheet(
                            title: Text(viewModel.dismissAlertTitle),
                            message: Text(viewModel.dismissAlertMessage),
                            buttons: [
                                .default(Text(Localization.remindLaterButton),
                                         action: {
                                             viewModel.remindLaterTapped()
                                             dismiss()
                                         }),
                                .default(Text(Localization.dontShowAgainButton),
                                         action: {
                                             viewModel.dontShowAgainTapped()
                                             dismiss()
                                         }),
                                .cancel()
                            ]
                        )
                    }
                }
            }
            .padding(.top, Layout.padding)

            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.title)
                    .headlineStyle()
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.message)
                            .bodyStyle()
                            .padding(.bottom, viewModel.buttonTitle == nil ? Layout.bottomNoButtonPadding : Layout.largeSpacing)

                        if let buttonTitle = viewModel.buttonTitle {
                            Button(buttonTitle) {
                                viewModel.ctaTapped()
                                callToAction?()
                            }
                            .padding(.bottom, Layout.bottomButtonPadding)
                            .foregroundColor(Color(.withColorStudio(.pink)))
                        }
                    }
                    Spacer()
                    if let imageUrl = viewModel.imageUrl {
                        AdaptiveAsyncImage(lightUrl: imageUrl, darkUrl: viewModel.imageDarkUrl) { imagePhase in
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
            .padding(.top, Layout.smallSpacing)
            .padding(.leading, Layout.padding)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

extension FeatureAnnouncementCardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let bottomButtonPadding: CGFloat = 23.5
        static let bottomNoButtonPadding: CGFloat = 60
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
    }
}

extension FeatureAnnouncementCardView {
    enum Localization {
        static let remindLaterButton = NSLocalizedString(
            "Remind me later",
            comment: "Alert button text on a feature announcement which gives the user the chance to be reminded " +
            "of the new feature after a short time")

        static let dontShowAgainButton = NSLocalizedString(
            "Don't show again",
            comment: "Alert button text on a feature announcement which prevents the banner being shown again")
    }
}

fileprivate struct AnimatedPlaceholder: View {
    @State var animate: Bool = false

    var body: some View {
        Rectangle()
            .fill(animate ? Color(.listForeground(modal: false)) : Color(.ghostCellAnimationEndColor))
            .aspectRatio(Constants.landscapeFourThirds, contentMode: .fit)
            .animation(.easeInOut(duration: GhostStyle.Defaults.beatDuration)
                .repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate.toggle()
            }
            .padding(Constants.placeholderPadding)
    }

    private enum Constants {
        static var landscapeFourThirds: CGFloat = 4/3
        static var placeholderPadding: CGFloat = 8
    }
}
