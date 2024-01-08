import Foundation
import Yosemite

/// View model for `BlazeTargetLanguagePickerView`
final class BlazeTargetLanguagePickerViewModel: ObservableObject {
    @Published private(set) var languages: [BlazeTargetLanguage] = []

    @Published var selectedLanguages: [BlazeTargetLanguage] = []

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    @MainActor
    func syncLanguages() async {
        // TODO
    }
}
