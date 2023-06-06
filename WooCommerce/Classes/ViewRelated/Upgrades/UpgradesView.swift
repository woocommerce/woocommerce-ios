import Foundation
import SwiftUI

/// Hosting controller for `UpgradesView`
/// To be used to display available plan Upgrades and the CTA to upgrade them
///
@MainActor
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    init(siteID: Int64) {
        super.init(rootView: UpgradesView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {
    var body: some View {
        VStack {
            Text("Upgrades view")
        }
    }
}
