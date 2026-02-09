import Testing
import UIKit
import WordPressUI

@MainActor
struct `Resources Bundle Tests` {

    @Test func `resource bundle image can be loaded`() {
        let icon = UIImage(named: "icon-url-field", in: Bundle.wordPressUIBundle, compatibleWith: nil)
        #expect(icon != nil)
    }

    @Test func `fancy alert storyboard can be loaded`() {
        let storyboard = UIStoryboard(name: "FancyAlerts", bundle: .wordPressUIBundle)
        #expect(storyboard.instantiateInitialViewController() != nil)
    }
}
