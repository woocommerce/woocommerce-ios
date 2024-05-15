import SwiftUI

final class CardReaderConnectionViewModel: ObservableObject {
    @Published private(set) var state: CardReaderConnectionUIState

    init(state: CardReaderConnectionUIState) {
        self.state = state
    }
}
