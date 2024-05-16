import Foundation
import UIKit

struct WrappedCardPresentPaymentsModalViewModel: Identifiable {
    var id = UUID()
    let topTitle: String
    let topSubtitle: String?
    let image: UIImage
    let bottomTitle: String?
    let bottomSubtitle: String?

    init(from content: CardPresentPaymentsModalContent) {
        self.topTitle = content.topTitle
        self.topSubtitle = content.topSubtitle
        self.image = content.image
        self.bottomTitle = content.bottomTitle
        self.bottomSubtitle = content.bottomSubtitle
    }
}
