import SwiftUI
import Yosemite

final class BetaFeaturesConfigurationViewController: UIHostingController<BetaFeaturesConfiguration> {

    init() {
        super.init(rootView: BetaFeaturesConfiguration(viewModel: .init()))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct BetaFeaturesConfiguration: View {
    @StateObject private var viewModel: BetaFeaturesConfigurationViewModel

    init(viewModel: BetaFeaturesConfigurationViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.availableFeatures) { feature in
                Section(footer: Text(feature.description)) {
                    TitleAndToggleRow(title: feature.title, isOn: viewModel.isOn(feature: feature))
                }
            }
        }
        .background(Color(.listForeground(modal: false)))
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
            BetaFeaturesConfiguration(viewModel: .init())
        }
    }
}
