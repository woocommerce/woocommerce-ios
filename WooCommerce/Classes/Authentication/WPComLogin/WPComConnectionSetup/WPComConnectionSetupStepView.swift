import SwiftUI

struct WPComConnectionSetupStepView: View {
    enum Status {
        case notStarted
        case running
        case success
        case failure(reason: String)

        var iconStatus: StatusIcon.Status {
            switch self {
            case .notStarted: return .notStarted
            case .running: return .running
            case .success: return .success
            case .failure: return .failure
            }
        }
    }

    let title: String
    let status: Status

    var body: some View {
        HStack(alignment: .center, spacing: Constants.horizontalSpacing) {
            StatusIcon(status: status.iconStatus)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
            VStack(alignment: .leading, spacing: Constants.detailVerticalSpacing) {
                Text(title)
                    .font(.body)
                    .bold()

                detail
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    fileprivate var detail: some View {
        switch status {
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
        WPComConnectionSetupStepView(title: title, status: .notStarted)
        WPComConnectionSetupStepView(title: title, status: .running)
        WPComConnectionSetupStepView(title: title, status: .success)
        WPComConnectionSetupStepView(title: title, status: .failure(reason: "Your current WooCommerce plugin version 10.3.4 needs updating"))
    }
}
