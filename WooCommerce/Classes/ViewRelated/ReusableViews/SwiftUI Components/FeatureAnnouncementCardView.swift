import SwiftUI

struct FeatureAnnouncementCardView: View {
    private let viewModel: FeatureAnnouncementCardViewModel

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
                        viewModel.dismissTapped()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(.withColorStudio(.gray)))
                    }.padding(.trailing, Layout.padding)
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
                            .padding(.bottom, viewModel.buttonTitle == nil ? Layout.bottomButtonLessPadding : Layout.largeSpacing)
                    }
                    .accessibilityElement(children: .combine)
                    if let buttonTitle = viewModel.buttonTitle {
                        Button(buttonTitle) {
                            viewModel.ctaTapped()
                            callToAction?()
                        }
                        .padding(.bottom, Layout.bottomButtonPadding)
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
        static let bottomButtonLessPadding: CGFloat = 60
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
    }
}
