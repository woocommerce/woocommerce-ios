import SwiftUI

/// Shows the drawer name recorded on a cash session when Core returns one.
struct POSCashSessionDrawerView: View {
    let drawerID: String

    var body: some View {
        POSInformationCard {
            VStack(alignment: .leading, spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(.secondary)
                Text(drawerID)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension POSCashSessionDrawerView {
    enum Localization {
        static let title = NSLocalizedString("pos.cashSession.drawerName.title", value: "Drawer name",
                                             comment: "Name of the cash drawer associated with a session")
    }
}

#if DEBUG
#Preview("Session drawer name") {
    POSCashSessionDrawerView(drawerID: "Front counter")
        .padding(POSPadding.medium)
        .background(Color.posSurface)
}
#endif
