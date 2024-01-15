import Foundation

final class BlazeAdDestinationSettingViewModel: ObservableObject {
    enum DestinationURLType {
        case product
        case home
    }

    let productURL: String
    let homeURL: String

    @Published private(set) var selectedDestinationType: DestinationURLType

    @Published private(set) var parameters: [BlazeAdURLParameter]

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
                    self.parameters.append(BlazeAdURLParameter(key: key, value: value))
                }
            }
        )
    }

    init (productURL: String,
          homeURL: String,
          selectedDestinationType: DestinationURLType = .product,
          parameters: [BlazeAdURLParameter] = []) {
        self.productURL = productURL
        self.homeURL = homeURL
        self.selectedDestinationType = selectedDestinationType
        self.parameters = parameters
    }

    func setDestinationType(as type: DestinationURLType) {
        selectedDestinationType = type
    }

    private func buildFinalDestinationURL() -> String {
        let baseURL: String
        switch selectedDestinationType {
        case .product:
            baseURL = productURL
        case .home:
            baseURL = homeURL
        }

        return baseURL + parameters.convertToQueryString()
    }

    func calculateRemainingCharacters() -> Int {
        let remainingCharacters = Constant.maxParameterLength - parameters.convertToQueryString().count
        // Should stop at zero and not show negative number.
        return max(0, remainingCharacters)
    }

    func selectParameter(item: BlazeAdURLParameter) {
        selectedParameter = item
    }

    func deleteParameter(at offsets: IndexSet) {
        parameters.remove(atOffsets: offsets)
    }

    private func updateSelectedParameter(newKey: String, newValue: String) {
        if let index = parameters.firstIndex(where: { $0.id == selectedParameter?.id }) {
            parameters[index] = BlazeAdURLParameter(key: newKey, value: newValue)
        }
    }

    private func clearSelectedParameter() {
        selectedParameter =  nil
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
            "Read like: Destination: https://woo.com/2022/04/11/product/?parameterkey=parametervalue"
        )
    }
}