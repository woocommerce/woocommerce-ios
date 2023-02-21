import SwiftUI

/// Shows a tappable onboarding task to set up the store. If the task is complete, a checkmark is shown.
struct StoreOnboardingTaskView: View {
    private let viewModel: StoreOnboardingViewModel.TaskViewModel
    private let onTap: (StoreOnboardingTask) -> Void

    init(viewModel: StoreOnboardingViewModel.TaskViewModel,
         onTap: @escaping (StoreOnboardingTask) -> Void) {
        self.viewModel = viewModel
        self.onTap = onTap
    }

    /// Scale of the view based on accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        Button {
            onTap(viewModel.task)
        } label: {
            HStack(alignment: .center, spacing: Layout.horizontalSpacing) {
                // Check icon or task icon.
                if viewModel.isComplete {
                    Image(uiImage: .checkCircleImage.withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .foregroundColor(.init(uiColor: .accent))
                        .frame(width: scale * Layout.imageDimension,
                               height: scale * Layout.imageDimension)
                } else {
                    Image(uiImage: viewModel.icon.withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .foregroundColor(.init(uiColor: .text))
                        .frame(width: scale * Layout.imageDimension,
                               height: scale * Layout.imageDimension)
                }

                VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                    Spacer().frame(height: Layout.spacerHeight)
                    // TODO: 8907 - show a chevron icon at the trailing edge
                    // Task title.
                    Text(viewModel.task.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    // Task subtitle.
                    Text(viewModel.task.subtitle)
                        .multilineTextAlignment(.leading)
                    Spacer().frame(height: Layout.spacerHeight)
                    Divider().dividerStyle()
                }
            }
            .padding(.horizontal, insets: Layout.taskInsets)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private extension StoreOnboardingTaskView {
    enum Layout {
        static let taskInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 4
        static let spacerHeight: CGFloat = 12
        static let imageDimension: CGFloat = 24
    }
}

private extension StoreOnboardingTask {
    var title: String {
        switch self {
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
                StoreOnboardingTaskView(viewModel: .init(task: .customizeDomains, isComplete: false, icon: .domainsImage), onTap: { _ in })
                StoreOnboardingTaskView(viewModel: .init(task: .customizeDomains, isComplete: true, icon: .domainsImage), onTap: { _ in })
            }
            .previewDisplayName("Customize your domains")
        }
    }
}
