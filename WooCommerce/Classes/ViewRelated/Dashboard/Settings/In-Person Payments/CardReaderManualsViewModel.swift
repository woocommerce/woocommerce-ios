import Foundation
import SwiftUI
import Yosemite

struct Manual: Identifiable {
    let id: Int
    let image: UIImage
    let name: String
    let urlString: String
}

final class CardReaderManualsViewModel {
    let manuals: [Manual]

    init(cardReaders: [CardReaderType] = [.chipper, .stripeM2, .wisepad3]) {
        self.manuals = cardReaders.map { $0.manual }
    }
}
