import Foundation
import UIKit

struct WrappedCardPresentPaymentsModalViewModel: Identifiable {
    var id = UUID()
    let topTitle: String
    let topSubtitle: String?
    let image: UIImage
    let bottomTitle: String?
    let bottomSubtitle: String?

    let primaryButtonViewModel: ButtonViewModel?
    let secondaryButtonViewModel: ButtonViewModel?
    let auxiliaryButtonViewModel: ButtonViewModel?

    init(from content: CardPresentPaymentsModalViewModel) {
        self.topTitle = content.topTitle
        self.topSubtitle = content.topSubtitle
        self.image = content.image
        self.bottomTitle = content.bottomTitle
        self.bottomSubtitle = content.bottomSubtitle

        self.primaryButtonViewModel = ButtonViewModel(label: content.primaryButtonTitle,
                                                      handler: content.primaryButtonTapped)
        self.secondaryButtonViewModel = ButtonViewModel(label: content.secondaryButtonTitle,
                                                        handler: content.secondaryButtonTapped)
        self.auxiliaryButtonViewModel = ButtonViewModel(label: content.auxiliaryButtonTitle,
                                                        handler: content.auxiliaryButtonTapped)
    }
}

struct ButtonViewModel {
    let label: String
    let handler: () -> Void

    init(label: String, handler: @escaping () -> Void) {
        self.label = label
        self.handler = handler
    }

    init?(label: String?, handler: (() -> Void)?) {
        guard let label, let handler else {
            return nil
        }
        self = ButtonViewModel(label: label, handler: handler)
    }
}
