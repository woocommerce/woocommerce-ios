import TipKit
import SwiftUI

/// A tip to explain the AI description feature in the product form.
@available(iOS 17.0, *)
struct ProductFormAITip: Tip, TipShim {
    var id: String {
        "product-form-ai-tip"
    }

    var title: Text {
        Text(Localization.title)
    }

    var message: Text? {
        Text(Localization.message)
    }

    var actions: [Tips.Action] {
        // Define a button to dismiss the tip.
        Action(id: "got-it", title: Localization.gotIt) {
            self.invalidate(reason: .tipClosed)
        }
    }

    var options: [Option] {
        /// Tip will only be shown 3 times.
        MaxDisplayCount(3)
    }

    /// Whether the AI description feature is enabled.
    @Parameter(.transient)
    static var isDescriptionAIEnabled: Bool = false

    /// Whether the product description is empty.
    @Parameter(.transient)
    static var emptyProductDescription: Bool = false

    var rules: [Rule] {
        #Rule(ProductFormAITip.$isDescriptionAIEnabled) {
            // This rule checks if the AI description feature is enabled.
            $0 == true
        }
        #Rule(ProductFormAITip.$emptyProductDescription) {
            // This rule checks if the product description is empty.
            $0 == true
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString("✨ Write with AI",
                                         comment: "The title of the Write with AI tooltip")
    static let message = NSLocalizedString("Use our AI-powered tool to quickly generate product descriptions. Just input keywords and we'll do the rest!",
                                           comment: "The message for the Write with AI tooltip")
    static let gotIt = NSLocalizedString("Got it",
                                         comment: "Button title that dismisses the Write with AI tooltip")
}
