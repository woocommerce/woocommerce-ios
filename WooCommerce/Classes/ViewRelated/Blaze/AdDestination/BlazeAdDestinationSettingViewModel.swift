import Foundation

final class BlazeAdDestinationSettingViewModel: ObservableObject {
    enum DestinationURLType {
        case product
        case home
    }

    var productURL: String
    var homeURL: String

    @Published var selectedDestinationType: DestinationURLType

    @Published var parameters: [BlazeAdURLParameters]

    var remainingCharactersLabel: String {
        let remainingCharacters = calculateRemainingCharacters()
        let lengthText = String.pluralize(remainingCharacters,
                                             singular: Localization.parameterCharactersLimit.singular,
                                             plural: Localization.parameterCharactersLimit.plural)
        return String(format: lengthText, remainingCharacters)
    }

    init (productURL: String,
          homeURL: String,
          selectedDestinationType: DestinationURLType = .product,
          parameters: [BlazeAdURLParameters] = []) {
        self.productURL = productURL
        self.homeURL = homeURL
        self.selectedDestinationType = selectedDestinationType
        self.parameters = parameters
    }

    func setDestinationType(type: DestinationURLType) {
        selectedDestinationType = type
    }

    private func calculateRemainingCharacters() -> Int {
        var parameterLength = 0
        for parameter in parameters {
            // In URL format, the parameter is written such as "key=value".
            parameterLength += parameter.key.count + "=".count + parameter.value.count
        }

        // Include also number of ampersands, which is used to separate parameters.
        // Exampe: "key1=value1&key2=value2"
        let numberOfAmpersands = max(0, parameters.count - 1)

        // Calculate remaining characters
        let remainingCharacters = Constant.maxParameterLength - (parameterLength + numberOfAmpersands)

        // If remainingCharacters is negative, return 0, else return the calculated value
        return max(0, remainingCharacters)
    }

    struct BlazeAdURLParameters {
        var key: String
        var value: String
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
            value: "Destination: %d",
            comment: "Blaze Ad Destination: The final URl destination including optional parameters. " +
            "Read like: Destination: https://woo.com/2022/04/11/product/?parameterkey=parametervalue"
        )
    }
}
