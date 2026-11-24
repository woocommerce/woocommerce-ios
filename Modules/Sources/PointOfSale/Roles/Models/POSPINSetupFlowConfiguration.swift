import Foundation

extension POSPINSetupFlow {
    struct Configuration: Equatable, Sendable {
        let role: POSLocalRole
        let copy: Copy
        let successAction: SuccessAction

        static let initialAdmin = Self(role: .admin, copy: .admin, successAction: .offerGuidedAccess)
        static let adminChange = Self(role: .admin, copy: .admin, successAction: .done)
        static let cashier = Self(role: .cashier, copy: .cashier, successAction: .done)

        private init(role: POSLocalRole, copy: Copy, successAction: SuccessAction) {
            self.role = role
            self.copy = copy
            self.successAction = successAction
        }

        struct Copy: Equatable, Sendable {
            let chooseTitle: String
            let confirmTitle: String
            let savedTitle: String
            let savedMessage: String

            fileprivate static let admin = Self(chooseTitle: Localization.chooseTitle,
                                                confirmTitle: Localization.confirmTitle,
                                                savedTitle: Localization.savedTitle,
                                                savedMessage: Localization.savedMessage)
            fileprivate static let cashier = Self(chooseTitle: Localization.chooseCashierTitle,
                                                  confirmTitle: Localization.confirmCashierTitle,
                                                  savedTitle: Localization.cashierSavedTitle,
                                                  savedMessage: Localization.cashierSavedMessage)
        }

        enum SuccessAction: Sendable {
            case offerGuidedAccess
            case done

            var title: String {
                switch self {
                case .offerGuidedAccess: Localization.continueAction
                case .done: Localization.done
                }
            }
        }
    }
}

private extension POSPINSetupFlow.Configuration {
    enum Localization {
        static let chooseCashierTitle = NSLocalizedString("pos.pinSetup.cashier.choose.title", value: "Choose a Cashier PIN",
                                                          comment: "Title while choosing a Cashier PIN in POS.")
        static let confirmCashierTitle = NSLocalizedString("pos.pinSetup.cashier.confirm.title", value: "Confirm the Cashier PIN",
                                                           comment: "Title while confirming a Cashier PIN in POS.")
        static let cashierSavedTitle = NSLocalizedString("pos.pinSetup.cashier.saved.title", value: "The cashier PIN is set",
                                                         comment: "Title after the Cashier PIN is saved in POS.")
        static let cashierSavedMessage = NSLocalizedString("pos.pinSetup.cashier.saved.message",
                                                           value: "Your team can use this PIN to unlock Point of Sale and process sales. " +
                                                           "Creating coupons, issuing refunds, and exiting Point of Sale require admin approval.",
                                                           comment: "Explains what the saved Cashier PIN permits in POS.")
        static let done = NSLocalizedString("pos.pinSetup.saved.done", value: "Done",
                                            comment: "Closes Cashier PIN setup or an Admin PIN change after saving.")
        static let chooseTitle = NSLocalizedString("pos.adminPINOnboarding.choose.title", value: "Choose your admin PIN",
                                                   comment: "Title while choosing an admin PIN in POS.")
        static let confirmTitle = NSLocalizedString("pos.adminPINOnboarding.confirm.title", value: "Confirm your admin PIN",
                                                    comment: "Title while re-entering an admin PIN in POS.")
        static let savedTitle = NSLocalizedString("pos.adminPINOnboarding.saved.title", value: "Your admin PIN is set",
                                                  comment: "Title after an admin PIN is saved in POS.")
        static let savedMessage = NSLocalizedString("pos.adminPINOnboarding.saved.message",
                                                    value: "Use your admin PIN to unlock Point of Sale with full access.",
                                                    comment: "Explanation after an admin PIN is saved in POS.")
        static let continueAction = NSLocalizedString("pos.adminPINOnboarding.saved.continue", value: "Continue",
                                                      comment: "Button after the admin PIN is saved. Shows the Guided Access offer.")
    }
}
