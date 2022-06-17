import SwiftUI
import Yosemite

final class BetaFeaturesConfigurationViewController: UIHostingController<BetaFeaturesConfiguration> {

    init() {
        super.init(rootView: BetaFeaturesConfiguration())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct BetaFeaturesConfiguration: View {
    let appSettings = ServiceLocator.generalAppSettings

    var body: some View {
        List {
            ForEach(BetaFeature.allCases) { feature in
                Section(footer: Text(feature.description)) {
                    TitleAndToggleRow(title: feature.title, isOn: appSettings.betaFeatureEnabledBinding(feature))
                }
            }
        }
        .background(Color(.listForeground))
        .listStyle(.grouped)
        .navigationTitle(Localization.title)
    }
}

private enum Localization {
    static let title = NSLocalizedString("Experimental Features", comment: "Experimental features navigation title")
}

struct BetaFeaturesConfiguration_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BetaFeaturesConfiguration()
        }
    }
}
