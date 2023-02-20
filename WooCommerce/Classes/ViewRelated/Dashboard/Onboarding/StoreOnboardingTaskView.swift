import SwiftUI

struct StoreOnboardingTaskView: View {
    let viewModel: StoreOnboardingViewModel.TaskViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack(alignment: .center) {
            // Check icon or task icon.
            if viewModel.isComplete {
                Image(uiImage: .checkCircleImage.withRenderingMode(.alwaysTemplate))
                    .foregroundColor(.init(uiColor: .accent))
                    .frame(width: scale * Layout.imageDimension,
                           height: scale * Layout.imageDimension)
            } else {
                Image(uiImage: viewModel.icon)
                    .frame(width: scale * Layout.imageDimension,
                           height: scale * Layout.imageDimension)
            }

            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                Spacer().frame(height: Layout.spacerHeight)
                Text(viewModel.task.title)
                    .fontWeight(.bold)
                Text(viewModel.task.subtitle)
                Spacer().frame(height: Layout.spacerHeight)
                Divider().dividerStyle()
            }
        }
        .padding(.horizontal, insets: Layout.taskInsets)
    }
}

private extension StoreOnboardingTaskView {
    enum Layout {
        static let taskInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let verticalSpacing: CGFloat = 4
        static let spacerHeight: CGFloat = 12
        static let imageDimension: CGFloat = 24
    }
}

private extension StoreOnboardingTask {
    var title: String {
        switch self {
        case .storeDetails:
            return NSLocalizedString(
                "Tell us more about your store",
                comment: "Title of the store onboarding task to add more store details."
            )
        case .addFirstProduct:
            return NSLocalizedString(
                "Add your first product",
                comment: "Title of the store onboarding task to add the first product."
            )
        case .launchStore:
            return NSLocalizedString(
                "Launch your store",
                comment: "Title of the store onboarding task to launch the store."
            )
        case .customizeDomains:
            return NSLocalizedString(
                "Customize your domain",
                comment: "Title of the store onboarding task to customize the store domain."
            )
        case .payments:
            return NSLocalizedString(
                "Get paid",
                comment: "Title of the store onboarding task to get paid."
            )
        }
    }

    var subtitle: String {
        switch self {
        case .storeDetails:
            return NSLocalizedString(
                "We’ll use the info to get a head start on your shipping, tax, and payments settings.",
                comment: "Subtitle of the store onboarding task to add more store details."
            )
        case .addFirstProduct:
            return NSLocalizedString(
                "Start selling by adding products or services to your store.",
                comment: "Subtitle of the store onboarding task to add the first product."
            )
        case .launchStore:
            return NSLocalizedString(
                "Publish your site to the world anytime you want!",
                comment: "Subtitle of the store onboarding task to launch the store."
            )
        case .customizeDomains:
            return NSLocalizedString(
                "Have a custom URL to host your store.",
                comment: "Subtitle of the store onboarding task to customize the store domain."
            )
        case .payments:
            return NSLocalizedString(
                "Give your customers an easy and convenient way to pay!",
                comment: "Subtitle of the store onboarding task to get paid."
            )
        }
    }
}

struct StoreOnboardingTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                StoreOnboardingTaskView(viewModel: .init(task: .customizeDomains, isComplete: false, icon: .domainsImage))
                StoreOnboardingTaskView(viewModel: .init(task: .customizeDomains, isComplete: true, icon: .domainsImage))
            }
            .previewDisplayName("Customize your domains")
        }
    }
}
