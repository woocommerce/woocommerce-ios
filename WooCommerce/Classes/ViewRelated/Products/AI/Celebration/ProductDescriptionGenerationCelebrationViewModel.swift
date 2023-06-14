import UIKit

/// View model for `ProductDescriptionGenerationCelebrationView`.
struct ProductDescriptionGenerationCelebrationViewModel {
    let greatStartLabel = Localization.greatStart

    let instructionsLabel = Localization.instructions

    let gotItButtonTitle = Localization.gotIt

    let celebrationImage = UIImage.aiDescriptionCelebrationImage

    let onTappingGotIt: () -> Void

    func didTapGotIt() {
        onTappingGotIt()
    }
}

private extension ProductDescriptionGenerationCelebrationViewModel {
    enum Localization {
        static let greatStart = NSLocalizedString("Great start!",
                                                  comment: "Title in AI product description celebration screen.")

        static let instructions = NSLocalizedString("Please keep in mind that this product description was generated using our AI-powered tool."
                                                    + " " +
                                                    "Please review and edit the content to ensure it aligns with your brand and messaging.",
                                                    comment: "Instructions to review the AI generated description.")

        static let gotIt = NSLocalizedString("Got it",
                                             comment: "Dismiss button title in AI product description celebration screen.")
    }
}
