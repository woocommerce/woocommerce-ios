import SwiftUI

/// Hosting controller that wraps the `StoreCreationCountryQuestionView`.
final class StoreCreationCountryQuestionHostingController: UIHostingController<StoreCreationCountryQuestionView> {
    init(viewModel: StoreCreationCountryQuestionViewModel) {
        super.init(rootView: StoreCreationCountryQuestionView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows the store country question in the store creation flow.
struct StoreCreationCountryQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationCountryQuestionViewModel

    init(viewModel: StoreCreationCountryQuestionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        RequiredStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(spacing: 16) {
                ForEach(viewModel.countryCodes, id: \.self) { countryCode in
                    Button(action: {
                        viewModel.selectCountry(countryCode)
                    }, label: {
                        HStack(spacing: 24) {
                            if let flagEmoji = countryCode.flagEmoji {
                                Text(flagEmoji)
                            }
                            Text(countryCode.readableCountry)
                            Spacer()
                        }
                    })
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedCountryCode == countryCode))
                }
            }
        }
    }
}

struct StoreCreationCountryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreCreationCountryQuestionView(viewModel: .init(storeName: "only in 2023", onContinue: { _ in }, onSkip: {}))
        }
    }
}
