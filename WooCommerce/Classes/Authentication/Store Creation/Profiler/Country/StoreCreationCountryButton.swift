import SwiftUI
import WooFoundation

/// A button for a country that the user can select for their store during the store creation profiler flow.
struct StoreCreationCountryButton: View {
    private let countryCode: CountryCode
    @ObservedObject private var viewModel: StoreCreationCountryQuestionViewModel

    init(countryCode: CountryCode, viewModel: StoreCreationCountryQuestionViewModel) {
        self.countryCode = countryCode
        self.viewModel = viewModel
    }

    var body: some View {
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

struct StoreCreationCountryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StoreCreationCountryButton(countryCode: .US,
                                       viewModel: .init(onContinue: { _ in },
                                                        onSupport: {}))
            StoreCreationCountryButton(countryCode: .UM,
                                       viewModel: .init(onContinue: { _ in },
                                                        onSupport: {}))
        }
    }
}
