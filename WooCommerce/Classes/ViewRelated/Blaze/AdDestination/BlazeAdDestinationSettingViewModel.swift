import Foundation

final class BlazeAdDestinationSettingViewModel: ObservableObject {
    enum DestinationURLType {
        case product
        case home
    }

    var productURL: String
    var homeURL: String

    @Published var selectedDestinationType: DestinationURLType

    @Published var parameters: [BlazeAdURLParameter]

    // Text to be shown on the view for remaining available characters for custom added parameters.
    var remainingCharactersLabel: String {
        let remainingCharacters = calculateRemainingCharacters()
        let lengthText = String.pluralize(remainingCharacters,
                                             singular: Localization.parameterCharactersLimit.singular,
                                             plural: Localization.parameterCharactersLimit.plural)
        return String(format: lengthText, remainingCharacters)
    }

    // Text to be shown on the view for the final ad campaign URL including parameters, if any.
    var finalDestinationLabel: String {
        return String(format: Localization.finalDestination, buildFinalDestinationURL())
    }

    init (productURL: String,
          homeURL: String,
          selectedDestinationType: DestinationURLType = .product,
          parameters: [BlazeAdURLParameter] = [BlazeAdURLParameter(key: "key1", value: "value1")]) {
        self.productURL = productURL
        self.homeURL = homeURL
        self.selectedDestinationType = selectedDestinationType
        self.parameters = parameters
    }

    func setDestinationType(type: DestinationURLType) {
        selectedDestinationType = type
    }

    // Parameter string should be in a format of "key=value&key2=value2&key3=value3"
    private var parameterString: String {
        parameters.map { $0.key + "=" + $0.value }.joined(separator: "&")
    }

    private func buildFinalDestinationURL() -> String {
        let baseURL: String
        switch selectedDestinationType {
        case .product:
            baseURL = productURL
        case .home:
            baseURL = homeURL
        }

        return baseURL + (parameterString.isEmpty ? "" : "?\(parameterString)")
    }

    private func calculateRemainingCharacters() -> Int {
        let remainingCharacters = Constant.maxParameterLength - parameterString.count
        // Should stop at zero and not show negative number.
        return max(0, remainingCharacters)
    }

    struct BlazeAdURLParameter: Equatable, Hashable {
        let key: String
        let value: String
    }
}

private extension BlazeAdDestinationSettingViewModel {
    enum Constant {
        static let maxParameterLength = 2096 // This number matches web implementation.
    }

    enum Localization {
        enum parameterCharactersLimit {
            static let plural = NSLocalizedString(
                "blazeAdDestinationSettingVieModel.parameterCharactersLimit.plural",
                value: "%d characters remaining",
                comment: "Blaze Ad Destination: Plural form for characters limit label %d will be replaced by a number. " +
                "Read like: 10 characters remaining"
            )

            static let singular = NSLocalizedString(
                "blazeAdDestinationSettingVieModel.parameterCharactersLimit.singular",
                value: "%d character remaining",
                comment: "Blaze Ad Destination: Singular form for characters limit label %d will be replaced by a number. " +
                "Read like: 1 character remaining"
            )
        }

        static let finalDestination = NSLocalizedString(
            "blazeAdDestinationSettingVieModel.finalDestination",
            value: "Destination: %1$@",
            comment: "Blaze Ad Destination: The final URl destination including optional parameters. " +
            "Read like: Destination: https://woo.com/2022/04/11/product/?parameterkey=parametervalue"
        )
    }
}
