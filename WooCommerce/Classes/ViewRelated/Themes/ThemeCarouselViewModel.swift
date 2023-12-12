import Foundation
import Yosemite

/// View model for `ThemeCarouselView`
///
final class ThemeCarouselViewModel: ObservableObject {

    @Published private(set) var themes: [WordPressTheme] = []

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

}
