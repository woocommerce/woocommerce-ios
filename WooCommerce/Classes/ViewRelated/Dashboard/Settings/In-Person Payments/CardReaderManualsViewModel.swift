import Foundation
import Yosemite

struct Manual: Identifiable, Equatable {
    let id: Int
    let image: UIImage
    let name: String
    let urlString: String
}

final class CardReaderManualsViewModel {
    var configurationLoader: CardPresentConfigurationLoader
    let manuals: [Manual]

    init() {
        // Initialize the ViewModel only with the supported readers for the specific store's country
        self.configurationLoader = CardPresentConfigurationLoader()
        let supportedReaders = configurationLoader.configuration.supportedReaders
        self.manuals = supportedReaders.compactMap { $0.manual }
    }
}
