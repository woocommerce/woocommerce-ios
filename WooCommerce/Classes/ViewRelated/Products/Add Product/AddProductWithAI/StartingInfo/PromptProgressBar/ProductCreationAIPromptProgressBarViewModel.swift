import SwiftUI

class ProductCreationAIPromptProgressBarViewModel: ObservableObject {
    @Published private(set) var status: ProgressStatus = .start
    @Published var text: String = "" {
        didSet {
            updateStatusBasedOnText(text)
        }
    }

    // Method for updating the text
    func updateText(to newText: String) {
        text = newText
    }

    // Method for updating the status based on text
    private func updateStatusBasedOnText(_ text: String) {
        let wordCount = text.split { $0 == " " || $0.isNewline }.count

        switch wordCount {
        case 0:
            status = .start
        case 1...7:
            status = .inProgress
        case 8...17:
            status = .halfway
        case 18...27:
            status = .almostDone
        default:
            status = .completed
        }
    }

    enum ProgressStatus: Int, CaseIterable {
        case start, inProgress, halfway, almostDone, completed

        var progress: Float {
            switch self {
            case .start:
                return 0.03
            case .inProgress:
                return 0.2
            case .halfway:
                return 0.4
            case .almostDone:
                return 0.7
            case .completed:
                return 0.9
            }
        }

        var color: Color {
            switch self {
            case .start:
                return Color.init(uiColor: .gray(.shade50))
            case .inProgress:
                return Color.init(uiColor: .withColorStudio(.red, shade: .shade50))
            case .halfway:
                return Color.init(uiColor: .withColorStudio(.orange, shade: .shade50))
            case .almostDone:
                return Color.init(uiColor: .withColorStudio(.yellow, shade: .shade50))
            case .completed:
                return Color.init(uiColor: .withColorStudio(.green, shade: .shade50))
            }
        }

        var mainDescription: String {
            switch self {
            case .start:
                return ""
            case .inProgress:
                return Localization.MainDescription.inProgressStatus
            case .halfway:
                return Localization.MainDescription.halfwayStatus
            case .almostDone:
                return Localization.MainDescription.almostDoneStatus
            case .completed:
                return Localization.MainDescription.completedStatus
            }
        }

        var secondaryDescription: String {
            switch self {
            case .start:
                return Localization.SecondaryDescription.startStatus
            case .inProgress:
                return Localization.SecondaryDescription.inProgressStatus
            case .halfway:
                return Localization.SecondaryDescription.halfwayStatus
            case .almostDone:
                return Localization.SecondaryDescription.almostDoneStatus
            case .completed:
                return Localization.SecondaryDescription.completedStatus
            }
        }
    }

    enum Localization {
        enum MainDescription {
            static let inProgressStatus = NSLocalizedString(
                    "productCreationAIPromptProgressBar.main.inProgress",
                    value: "Add more details.",
                    comment: "State when more details need to be added for the main prompt description suggestion in product creation with AI."
                ) + " "
            static let halfwayStatus = NSLocalizedString(
                    "productCreationAIPromptProgressBar.main.halfway",
                    value: "Getting better.",
                    comment: "State when the prompt description is improving for the main prompt description suggestion in product creation with AI."
                ) + " "
            static let almostDoneStatus = NSLocalizedString(
                    "productCreationAIPromptProgressBar.main.almostDone",
                    value: "Almost there.",
                    comment: "State when the prompt description is almost there for the main prompt description suggestion in product creation with AI."
                )
            static let completedStatus = NSLocalizedString(
                    "productCreationAIPromptProgressBar.main.completed",
                    value: "Great prompt!",
                    comment: "State when the prompt description is completed and great for the main prompt description suggestion in product creation with AI."
                )
        }

        enum SecondaryDescription {
            static let startStatus = NSLocalizedString(
                "productCreationAIPromptProgressBar.secondary.start",
                value: "Add your product’s name and key features, benefits, or details to help it get found online.",
                comment: "Initial state with instructions to add product name and key details for the prompt description in product creation with AI."
            )
            static let inProgressStatus = NSLocalizedString(
                "productCreationAIPromptProgressBar.secondary.inProgress",
                value: "The more details you provide, the better your generated details will be.",
                comment: "State when more details will improve the generated content for the prompt description in product creation with AI."
            )
            static let halfwayStatus = NSLocalizedString(
                "productCreationAIPromptProgressBar.secondary.halfway",
                value: "Can you describe the fit and any distinctive features of the item?",
                comment: "State when the description should include fit and distinctive features for the prompt description in product creation with AI."
            )
            static let almostDoneStatus = NSLocalizedString(
                "productCreationAIPromptProgressBar.secondary.almostDone",
                value: "Mention additional relevant information or characteristics.",
                comment: "State prompting for more additional relevant info of the product for the prompt description in product creation with AI."
            )
            static let completedStatus =  NSLocalizedString(
                "productCreationAIPromptProgressBar.secondary.completed",
                value: "You've given us enough to work with, but you may add more detail to make it even better.",
                comment: "State indicating sufficient details have been provided, more can be added for the prompt description in product creation with AI."
            )
        }
    }
}
