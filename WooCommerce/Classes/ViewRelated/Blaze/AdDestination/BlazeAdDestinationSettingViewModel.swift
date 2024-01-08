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

    var finalDestinationLabel: String {
        let baseURL: String
        switch selectedDestinationType {
        case .product:
            baseURL = productURL
        case .home:
            baseURL = homeURL
        }

        let paramString = buildParameterString()
        let finalURL = baseURL + (paramString.isEmpty ? "" : "?\(paramString)")

        return String(format: Localization.finalDestination, finalURL)
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

    func buildParameterString() -> String {
        var parameterString = ""
        for parameter in parameters {
            // In URL format, the parameter is written such as "key=value".
            parameterString += parameter.key + "=" + parameter.value

            // If it's not the last parameter, add an ampersand.
            if parameter != parameters.last {
                parameterString += "&"
            }
        }

        return parameterString
    }

    private func calculateRemainingCharacters() -> Int {
        let remainingCharacters = Constant.maxParameterLength - buildParameterString().count
        // Should stop at zero and not show negative number.
        return max(0, remainingCharacters)
    }

    struct BlazeAdURLParameters: Equatable {
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
            value: "Destination: %1$@",
            comment: "Blaze Ad Destination: The final URl destination including optional parameters. " +
            "Read like: Destination: https://woo.com/2022/04/11/product/?parameterkey=parametervalue"
        )
    }
}
