import SwiftUI

struct FeatureAnnouncementCardView: View {
    private let viewModel: FeatureAnnouncementCardViewModel
    @State private var showingDismissActionSheet = false

    let dismiss: (() -> Void)?
    let callToAction: (() -> Void)?

    init(viewModel: FeatureAnnouncementCardViewModel,
         dismiss: (() -> Void)? = nil,
         callToAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.dismiss = dismiss
        self.callToAction = callToAction
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                NewBadgeView()
                    .padding(.leading, Layout.padding)
                Spacer()
                if let dismiss = dismiss {
                    Button(action: {
                        showingDismissActionSheet = true
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

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.title)
                            .headlineStyle()
                            .padding(.bottom, Layout.smallSpacing)
                        Text(viewModel.message)
                            .bodyStyle()
                            .padding(.bottom, viewModel.buttonTitle == nil ? Layout.bottomNoButtonPadding : Layout.largeSpacing)
                    }
                    .accessibilityElement(children: .combine)
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
                Image(uiImage: viewModel.image)
                    .accessibilityHidden(true)
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
