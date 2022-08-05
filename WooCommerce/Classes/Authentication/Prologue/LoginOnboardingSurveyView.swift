import SwiftUI

/// Options for the login onboarding survey.
enum LoginOnboardingSurveyOption: CaseIterable {
    case exploring
    case settingUpStore
    case analytics
    case products
    case orders
    case multipleStores
}

/// Contains a title and options for the login onboarding survey.
struct LoginOnboardingSurveyView: View {
    private let onSelection: (LoginOnboardingSurveyOption) -> Void

    private let options = LoginOnboardingSurveyOption.allCases
    @State private var selectedOption: LoginOnboardingSurveyOption?

    /// - Parameter onSelection: called when an option is selected.
    init(onSelection: @escaping (LoginOnboardingSurveyOption) -> Void) {
        self.onSelection = onSelection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 52) {
            Text(Localization.title)
                .secondaryTitleStyle()

            VStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    // An if/else is used instead of `.buttonStyle(ButtonStyle(isSelected: selectedOption == option))`
                    // because a weird background color is set to the button briefly after it is selected in the latter case.
                    if selectedOption == option {
                        button(option: option).buttonStyle(SelectableSecondaryButtonStyle(isSelected: true))
                    } else {
                        button(option: option).buttonStyle(SelectableSecondaryButtonStyle(isSelected: false))
                    }

                }
            }
        }
        .scrollVerticallyIfNeeded()
        .padding(.init(top: 52, leading: 16, bottom: 52, trailing: 16))
    }

    private func button(option: LoginOnboardingSurveyOption) -> some View {
        Button(Localization.title(for: option)) {
            onSelection(option)
            selectedOption = option
        }
    }
}

private extension LoginOnboardingSurveyView {
    enum Localization {
        static let title = NSLocalizedString("What brings you to the WooCommerce app today?",
                                             comment: "Login onboarding survey title.")
        static func title(for surveyOption: LoginOnboardingSurveyOption) -> String {
            switch surveyOption {
            case .exploring:
                return NSLocalizedString("Just exploring", comment: "Login onboarding survey option: just exploring.")
            case .settingUpStore:
                return NSLocalizedString("Trying to set up a store", comment: "Login onboarding survey option: trying to set up a store.")
            case .analytics:
                return NSLocalizedString("Check my analytics", comment: "Login onboarding survey option: check my analytics.")
            case .products:
                return NSLocalizedString("Create or update my products", comment: "Login onboarding survey option: create or update my products.")
            case .orders:
                return NSLocalizedString("Manage my orders", comment: "Login onboarding survey option: manage my orders.")
            case .multipleStores:
                return NSLocalizedString("Switch between multiple Stores", comment: "Login onboarding survey option: switch between multiple Stores.")
            }
        }
    }
}

struct LoginOnboardingSurveyView_Previews: PreviewProvider {
    static var previews: some View {
        LoginOnboardingSurveyView(onSelection: { _ in })
    }
}
