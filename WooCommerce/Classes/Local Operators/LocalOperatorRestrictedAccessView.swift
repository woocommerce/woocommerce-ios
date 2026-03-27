import SwiftUI

struct LocalOperatorRestrictedAccessView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(Color(uiColor: .textSubtle))
            Text(Localization.title)
                .font(.headline)
            Text(Localization.message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .listBackground))
    }
}

private extension LocalOperatorRestrictedAccessView {
    enum Localization {
        static let title = NSLocalizedString("Restricted Access", comment: "Title for local operator restricted access view.")
        static let message = NSLocalizedString(
            "The current operator does not have permission to open this area on this device.",
            comment: "Message shown when a local operator tries to access a restricted area."
        )
    }
}
