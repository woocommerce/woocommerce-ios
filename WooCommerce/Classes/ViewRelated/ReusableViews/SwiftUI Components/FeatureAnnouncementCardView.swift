import SwiftUI

struct FeatureAnnouncementCardView: View {
    private let viewModel: FeatureAnnouncementCardViewModel
    @State private var showingDismissAlert = false

    let dismiss: (() -> Void)?
    let callToAction: (() -> Void)

    init(viewModel: FeatureAnnouncementCardViewModel,
         dismiss: (() -> Void)? = nil,
         callToAction: @escaping (() -> Void)) {
        self.viewModel = viewModel
        self.dismiss = dismiss
        self.callToAction = callToAction
    }

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                NewBadgeView()
                    .padding(.leading, Layout.padding)
                Spacer()
                if let dismiss = dismiss {
                    Button(action: {
                        showingDismissAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(.withColorStudio(.gray)))
                    }
                    .padding(.trailing, Layout.padding)
                    .alert(isPresented: $showingDismissAlert,
                           content: {
                        Alert(title: Text(viewModel.dismissAlertTitle),
                              message: Text(viewModel.dismissAlertMessage),
                              primaryButton: .cancel(Text(Localization.remindLaterButton), action: {
                            viewModel.remindLaterTapped()
                            dismiss()
                        }),
                              secondaryButton: .default(Text(Localization.dontShowAgainButton), action: {
                            viewModel.dontShowAgainTapped()
                            dismiss()
                        }))
                    })
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
                            .padding(.bottom, Layout.largeSpacing)
                    }
                    .accessibilityElement(children: .combine)
                    Button(viewModel.buttonTitle) {
                        viewModel.ctaTapped()
                        callToAction()
                    }
                    .padding(.bottom, Layout.bottomButtonPadding)
                }
                Spacer()
                Image(uiImage: viewModel.image)
                    .accessibilityHidden(true)
            }
            .padding(.top, Layout.smallSpacing)
            .padding(.leading, Layout.padding)
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground).ignoresSafeArea())
        .onAppear {
            viewModel.onAppear()
        }
    }
}

extension FeatureAnnouncementCardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let bottomButtonPadding: CGFloat = 23.5
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
