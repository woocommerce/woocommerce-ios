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
        case .failure(reason: let reason):
            Text(reason)
                .foregroundColor(Color(uiColor: .error))
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
    }
}

#Preview {
    let title = "Connect store to WordPress.com"
    VStack(alignment: .leading, spacing: 16) {
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title, status: .notStarted))
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title, status: .running))
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title, status: .success))
        WPComConnectionSetupStepView(step: WPComConnectionSetupStep(title: title,
                                                                          status: .failure(reason: "Plugin version 10.3.4 needs updating")))
    }
}
