import SwiftUI
import Yosemite

final class BetaFeaturesConfigurationViewController: UIHostingController<BetaFeaturesConfiguration> {
    private let rowLayout: BetaFeaturesRowLayout

    init() {
        let rowLayout = BetaFeaturesRowLayout()
        self.rowLayout = rowLayout
        super.init(rootView: BetaFeaturesConfiguration(viewModel: .init(), rowLayout: rowLayout))
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        updateRowInsets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRowInsets()
    }

    private func updateRowInsets() {
        // The SwiftUI size class can be unspecified in this hosting path.
        let inset = max(systemMinimumLayoutMargins.leading, systemMinimumLayoutMargins.trailing)
        guard inset > 0, rowLayout.horizontalInset != inset else {
            return
        }
        rowLayout.horizontalInset = inset
    }
}

struct BetaFeaturesConfiguration: View {
    @ObservedObject private var rowLayout: BetaFeaturesRowLayout
    @StateObject private var viewModel: BetaFeaturesConfigurationViewModel
    @State private var destinationURL: URL?

    init(viewModel: BetaFeaturesConfigurationViewModel) {
        self.init(viewModel: viewModel, rowLayout: .init())
    }

    fileprivate init(viewModel: BetaFeaturesConfigurationViewModel, rowLayout: BetaFeaturesRowLayout) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.rowLayout = rowLayout
    }

    var body: some View {
        List {
            ForEach(viewModel.availableFeatures) { feature in
                Section {
                    TitleAndToggleRow(title: feature.title, isOn: viewModel.isOn(feature: feature))
                        .betaRowHorizontalInsets(rowLayout.horizontalInset)
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
                        .betaRowHorizontalInsets(rowLayout.horizontalInset)
                    } else {
                        Text(feature.description)
                            .betaRowHorizontalInsets(rowLayout.horizontalInset)
                    }
                }
            }
        }
        .listStyle(.grouped)
        // Native list cells can paint outside the layout's safe-area width on Duo.
        .mask(Rectangle().ignoresSafeArea(.container, edges: .bottom))
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Localization.title)
        .safariSheet(url: $destinationURL)
    }
}

fileprivate final class BetaFeaturesRowLayout: ObservableObject {
    @Published var horizontalInset: CGFloat?
}

private extension View {
    @ViewBuilder func betaRowHorizontalInsets(_ inset: CGFloat?) -> some View {
        if #available(iOS 26, *) {
            listRowInsets(.horizontal, inset)
        } else {
            self
        }
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
