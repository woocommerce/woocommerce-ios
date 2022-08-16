import Foundation
import Yosemite

struct Manual: Identifiable, Equatable {
    let id: Int
    let image: UIImage
    let name: String
    let urlString: String
}

final class CardReaderManualsViewModel {
    let manuals: [Manual]

    init() {
        // Display all card readers at all times. Ref: pdfdoF-1aF-p2
        self.manuals = CardReaderType.allSupportedReaders.map { $0.manual }
    }
}
