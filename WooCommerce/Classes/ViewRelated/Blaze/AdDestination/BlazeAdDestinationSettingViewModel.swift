import Foundation
import protocol WooFoundation.Analytics

final class BlazeAdDestinationSettingViewModel: ObservableObject {
    enum DestinationURLType {
        case product
        case home
    }

    typealias BlazeAdDestinationSettingCompletionHandler = (_ targetUrl: String, _ urlParams: String) -> Void

    let productURL: String
    let homeURL: String
    let initialFinalDestinationURL: String

    @Published private(set) var selectedDestinationType: DestinationURLType = .product

    @Published private(set) var parameters: [BlazeAdURLParameter] = []

    // This is used as a flag whether merchant wants to add a new parameter (if nil) or update an existing one (if not)
    var selectedParameter: BlazeAdURLParameter?

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

    var shouldDisableSaveButton: Bool {
        buildFinalDestinationURL() == initialFinalDestinationURL
    }

    // View model for the add parameter view.
    var blazeAddParameterViewModel: BlazeAddParameterViewModel {

        // The remaining characters to be used for validation in `BlazeAddParameterViewModel`.
        // If more than 1 parameter exist and user is adding a new character, the value should be reduced further by 1.
        // This to take into account the need to add "&" separator character to the new parameter.
        let adjustedRemainingCharacters: Int = {
            let remainingCharacters = calculateRemainingCharacters()
            if parameters.count > 1 && selectedParameter == nil {
                return remainingCharacters - 1
            }
            return remainingCharacters
        }()

        return BlazeAddParameterViewModel(
            remainingCharacters: adjustedRemainingCharacters,
            parameter: selectedParameter,
            onCancel: { [weak self] in
                guard let self = self else { return }
                self.clearSelectedParameter()
            },
            onCompletion: { [weak self] key, value in
                guard let self = self else { return }

                if selectedParameter != nil {
                    updateSelectedParameter(newKey: key, newValue: value)

                    // Once a parameter is updated, clear the selected parameter to prepare for the next add/update action.
                    clearSelectedParameter()
                } else {
                    addNewParameter(item: BlazeAdURLParameter(key: key, value: value))
                }
            }
        )
    }

    var shouldDisableAddParameterButton: Bool {
        calculateRemainingCharacters() == 0
    }

    private let analytics: Analytics
    private let onSave: BlazeAdDestinationSettingCompletionHandler

    private var baseURL: String {
        switch selectedDestinationType {
        case .product:
            productURL
        case .home:
            homeURL
        }
    }

    init(productURL: String,
         homeURL: String,
         finalDestinationURL: String,
         analytics: Analytics = ServiceLocator.analytics,
         onSave: @escaping BlazeAdDestinationSettingCompletionHandler) {
        self.productURL = productURL
        self.homeURL = homeURL
        self.initialFinalDestinationURL = finalDestinationURL
        self.analytics = analytics
        self.onSave = onSave

        initializeDestinationType()
        initializeParameters()
    }

    func setDestinationType(as type: DestinationURLType) {
        selectedDestinationType = type
    }

    func confirmSave() {
        analytics.track(event: .Blaze.AdDestination.saveTapped())
        onSave(baseURL, parameters.convertToQueryString())
    }

    func calculateRemainingCharacters() -> Int {
        let remainingCharacters = Constant.maxParameterLength - parameters.convertToQueryString().count
        let parameterLengthInBaseURL: Int = {
            return baseURL.urlParameters
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
                .count
        }()
        // Should stop at zero and not show negative number.
        return max(0, remainingCharacters - parameterLengthInBaseURL)
    }

    func selectParameter(item: BlazeAdURLParameter) {
        selectedParameter = item
    }

    func addNewParameter(item: BlazeAdURLParameter) {
        parameters.append(item)
    }

    func deleteParameter(at offsets: IndexSet) {
        parameters.remove(atOffsets: offsets)
    }
}

private extension BlazeAdDestinationSettingViewModel {
    func initializeDestinationType() {
        if productURL.isNotEmpty,
           initialFinalDestinationURL.hasPrefix(productURL) {
            selectedDestinationType = .product
        } else {
            selectedDestinationType = .home
        }
    }

    func initializeParameters() {
        if let finalDestinationURL = URL(string: initialFinalDestinationURL),
           let urlComponents = URLComponents(url: finalDestinationURL, resolvingAgainstBaseURL: false) {
            parameters = urlComponents.toBlazeAdURLParameters(baseURL: baseURL)
        }
    }

    func updateSelectedParameter(newKey: String, newValue: String) {
        if let index = parameters.firstIndex(where: { $0.id == selectedParameter?.id }) {
            parameters[index] = BlazeAdURLParameter(key: newKey, value: newValue)
        }
    }

    func clearSelectedParameter() {
        selectedParameter =  nil
    }

    func buildFinalDestinationURL() -> String {
        guard parameters.isNotEmpty else {
            return baseURL
        }

        let connectingCharacter: String
        if baseURL.urlParameters.isNotEmpty {
            /// If there are existing query params, connecting the base URL with new parameters using "&"
            connectingCharacter = "&"
        } else {
            connectingCharacter = "?"
        }

        return baseURL + connectingCharacter + parameters.convertToQueryString()
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
                value: "%1$d characters remaining",
                comment: "Blaze Ad Destination: Plural form for characters limit label. %1$d will be replaced by a number. " +
                "Read like: 10 characters remaining"
            )

            static let singular = NSLocalizedString(
                "blazeAdDestinationSettingVieModel.parameterCharactersLimit.singular",
                value: "%1$d character remaining",
                comment: "Blaze Ad Destination: Singular form for characters limit label. %1$d will be replaced by a number. " +
                "Read like: 1 character remaining"
            )
        }

        static let finalDestination = NSLocalizedString(
            "blazeAdDestinationSettingVieModel.finalDestination",
            value: "Destination: %1$@",
            comment: "Blaze Ad Destination: The final URl destination including optional parameters. " +
            "%1$@ will be replaced by the URL text. " +
            "Read like: Destination: https://woocommerce.com/2022/04/11/product/?parameterkey=parametervalue"
        )
    }
}

/// Convert a URLComponents's query items to BlazeAdURLParameter array.
private extension URLComponents {
    func toBlazeAdURLParameters(baseURL: String) -> [BlazeAdURLParameter] {
        guard let queryItems else { return [] }

        return queryItems
            .filter { item in
                // ignores items in the base URL to keep them fixed
                !baseURL.urlParameters.contains { $0.name == item.name }
            }
            .map {
                // URLQueryItem's `value` is an optional String,
                // so here we're converting to empty string if needed.
                BlazeAdURLParameter(key: $0.name, value: $0.value ?? "")
            }
    }
}

private extension String {
    var urlParameters: [URLQueryItem] {
       if let url = URL(string: self),
          let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = urlComponents.queryItems, queryItems.isNotEmpty {
           return queryItems
       }
        return []
    }
}
