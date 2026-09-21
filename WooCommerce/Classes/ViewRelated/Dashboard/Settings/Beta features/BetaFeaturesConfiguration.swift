import SwiftUI
import Yosemite

final class BetaFeaturesConfigurationViewController: UIHostingController<BetaFeaturesConfiguration> {

    init() {
        super.init(rootView: BetaFeaturesConfiguration(viewModel: .init()))
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct BetaFeaturesConfiguration: View {
    @StateObject private var viewModel: BetaFeaturesConfigurationViewModel
    @State private var destinationURL: URL?

    init(viewModel: BetaFeaturesConfigurationViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.availableFeatures) { feature in
                Section {
                    TitleAndToggleRow(title: feature.title, isOn: viewModel.isOn(feature: feature))
                } footer: {
                    if let link = feature.descriptionLink {
                        Text(
                            .withEmbeddedLink(
                                mainContent: feature.description,
                                linkText: link.text,
                                link: link.url.absoluteString,
                                font: nil,
                                foregroundColor: nil
                            )
                        )
                        .environment(\.openURL, OpenURLAction { url in
                            destinationURL = url
                            return .handled
                        })
                    } else {
                        Text(feature.description)
                    }
                }
            }
        }
        .background(Color(.listForeground(modal: false)))
        .listStyle(.grouped)
        .navigationTitle(Localization.title)
        .safariSheet(url: $destinationURL)
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
