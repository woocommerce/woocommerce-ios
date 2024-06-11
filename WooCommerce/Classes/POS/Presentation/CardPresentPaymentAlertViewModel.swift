import Foundation
import SwiftUI

struct CardPresentPaymentAlertViewModel {
    init(alertDetails: CardPresentPaymentAlertDetails) {
        self.topTitle = ""
        self.topSubtitle = nil
        self.showLoadingIndicator = false
        self.image = Image(systemName: "plus")
        self.bottomTitle = nil
        self.bottomSubtitle = nil
        self.primaryButtonViewModel = nil
        self.secondaryButtonViewModel = nil
        self.auxiliaryButtonViewModel = nil
    }

    let topTitle: String
    let topSubtitle: String?
    let showLoadingIndicator: Bool
    let image: Image
    let bottomTitle: String?
    let bottomSubtitle: String?
    let primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
    let secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
    let auxiliaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
}
