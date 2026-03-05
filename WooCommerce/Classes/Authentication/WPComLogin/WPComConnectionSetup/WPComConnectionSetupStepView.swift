import SwiftUI

struct WPComConnectionSetupStepView: View {
    let step: WPComConnectionSetupStep

    var body: some View {
        HStack(alignment: .center, spacing: Constants.horizontalSpacing) {
            StatusIcon(status: step.status.iconStatus)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
            VStack(alignment: .leading, spacing: Constants.detailVerticalSpacing) {
                Text(step.title)
                    .font(.body)
                    .bold()

                detail
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch step.status {
        case .notStarted:
            Text(Localization.notStarted)
                .foregroundStyle(Color.secondary)
        case .running:
            Text(Localization.inProgress)
                .foregroundStyle(Color.secondary)
        case .success:
            Text(Localization.complete)
                .foregroundColor(Color(uiColor: .success))
        case .failure(error: let error):
            Text(errorMessage(for: error))
                .foregroundColor(Color(uiColor: .error))
        }
    }

    private func errorMessage(for error: WPComConnectionSetupStep.ErrorType) -> String {
        switch error {
        case .outdatedPlugin(let version):
            return String(format: Localization.outdatedPlugin, version)
        case .generic(let reason):
            return reason
        }
    }
}

private extension WPComConnectionSetupStep.Status {
    var iconStatus: StatusIcon.Status {
        switch self {
        case .notStarted: return .notStarted
        case .running: return .running
        case .success: return .success
        case .failure: return .failure
        }
    }
}

private extension WPComConnectionSetupStepView {
    enum Constants {
        static let horizontalSpacing: CGFloat = 16
        static let detailVerticalSpacing: CGFloat = 0
        static let iconSize: CGFloat = 24
    }

    enum Localization {
        static let notStarted = NSLocalizedString(
            "wpComConnectionSetupStepView.notStarted",
            value: "Not started",
            comment: "Status label shown when a setup step has not been started yet."
        )
        static let inProgress = NSLocalizedString(
            "wpComConnectionSetupStepView.inProgress",
            value: "In progress",
            comment: "Status label shown when a setup step is currently running."
        )
        static let complete = NSLocalizedString(
            "wpComConnectionSetupStepView.complete",
            value: "Complete",
            comment: "Status label shown when a setup step has completed successfully."
        )
        static let outdatedPlugin = NSLocalizedString(
            "wpComConnectionSetupStepView.outdatedPlugin",
            value: "Your current WooCommerce plugin version %1$@ needs updating to fully connect your store to WordPress.com.",
            comment: "Error message when the WooCommerce plugin version is outdated. %@ is the current plugin version."
        )
    }
}

#Preview {
    let title = "Connect store to WordPress.com"
    VStack(alignment: .leading, spacing: 16) {
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title, status: .notStarted))
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title, status: .running))
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title, status: .success))
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title,
                                                                          status: .failure(error: .outdatedPlugin(version: "10.3.4"))))
    }
}
