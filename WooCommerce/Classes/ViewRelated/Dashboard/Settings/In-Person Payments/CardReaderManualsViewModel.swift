import Foundation
import SwiftUI
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
        // Initialize the View Model only with the supported readers for a specific Store
        self.configurationLoader = CardPresentConfigurationLoader()
        let supportedReaders = configurationLoader.configuration.supportedReaders
        self.manuals = supportedReaders.map { $0.manual }
    }
}
