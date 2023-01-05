import SwiftUI

/// Shows a header label and a list of countries for selection in the store creation profiler flow.
struct StoreCreationCountrySectionView: View {
    private let header: String
    private let countryCodes: [SiteAddress.CountryCode]
    @ObservedObject private var viewModel: StoreCreationCountryQuestionViewModel

    init(header: String, countryCodes: [SiteAddress.CountryCode], viewModel: StoreCreationCountryQuestionViewModel) {
        self.header = header
        self.countryCodes = countryCodes
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .footnoteStyle()
            VStack(spacing: 16) {
                ForEach(countryCodes, id: \.self) { countryCode in
                    StoreCreationCountryButton(countryCode: countryCode,
                                               viewModel: viewModel)
                }
            }
        }
    }
}

struct StoreCreationCountrySectionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationCountrySectionView(header: "EXAMPLES", countryCodes: [.FJ, .UM, .US], viewModel: .init(storeName: "", onContinue: { _ in }, onSupport: {}))
    }
}
