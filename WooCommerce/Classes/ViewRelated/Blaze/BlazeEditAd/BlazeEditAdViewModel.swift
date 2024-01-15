import Foundation
import Combine
import struct Networking.BlazeAISuggestion

/// View model for `BlazeEditAdView`
final class BlazeEditAdViewModel: ObservableObject {
    typealias ImageState = EditableImageViewState

    let siteID: Int64
    private let adData: BlazeEditAdData

    // Image selection
    var onAddImage: ((MediaPickingSource) async -> MediaPickerImage?)?
    @Published private(set) var imageState: ImageState
    var image: MediaPickerImage? {
        imageState.image
    }

    // Tagline
    @Published var tagline: String = ""
    var taglineFooterText: String {
        taglineEmptyError ?? taglineLengthLimitLabel
    }
    private let taglineMaxLength = 32
    @Published private var taglineRemainingLength: Int
    private var taglineLengthLimitLabel: String {
        let lengthText = String.pluralize(taglineRemainingLength,
                                          singular: Localization.LengthLimit.singular,
                                          plural: Localization.LengthLimit.plural)
        return String(format: lengthText, taglineRemainingLength)
    }
    private var taglineEmptyError: String?

    // Description
    @Published var description: String = ""
    var descriptionFooterText: String {
        descriptionEmptyError ?? descriptionLengthLimitLabel
    }
    private let descriptionMaxLength = 140
    @Published private var descriptionRemainingLength: Int
    private var descriptionLengthLimitLabel: String {
        let lengthText = String.pluralize(descriptionRemainingLength,
                                          singular: Localization.LengthLimit.singular,
                                          plural: Localization.LengthLimit.plural)
        return String(format: lengthText, descriptionRemainingLength)
    }
    private var descriptionEmptyError: String?

    var isSaveButtonEnabled: Bool {
        guard let editedAdData else {
            return false
        }

        return editedAdData != adData
    }

    private var editedAdData: BlazeEditAdData? {
        guard let image,
              tagline.isNotEmpty,
              description.isNotEmpty else {
            return nil
        }
        return BlazeEditAdData(image: image,
                               tagline: tagline,
                               description: description)
    }

    @Published private var selectedSuggestionIndex: Int?
    private let suggestions: [BlazeAISuggestion]

    var canSelectPreviousSuggestion: Bool {
        guard let selectedSuggestionIndex else {
            return false
        }
        return selectedSuggestionIndex > 0
    }

    var canSelectNextSuggestion: Bool {
        guard let selectedSuggestionIndex else {
            return true
        }
        return selectedSuggestionIndex < suggestions.count - 1
    }

    private let onSave: (BlazeEditAdData) -> Void
    private let analytics: Analytics
    private var subscriptions: Set<AnyCancellable> = []

    init(siteID: Int64,
         adData: BlazeEditAdData,
         suggestions: [BlazeAISuggestion],
         onSave: @escaping (BlazeEditAdData) -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID

        self.adData = adData
        self.suggestions = suggestions
        if let image = adData.image {
            self.imageState = .success(image)
        } else {
            self.imageState = .empty
        }
        self.tagline = adData.tagline
        self.description = adData.description

        self.onSave = onSave
        self.analytics = analytics
        self.taglineRemainingLength = taglineMaxLength
        self.descriptionRemainingLength = descriptionMaxLength

        watchCharacterLimit()
        setSelectedSuggestionIfApplicable()
    }

    func didTapSave() {
        // TODO: 11512 Track Save button tap
        guard let editedAdData else {
            assertionFailure("Save button shouldn't be enabled when edited ad is nil")
            return
        }
        onSave(editedAdData)
    }

    func didTapCancel() {
        // TODO: 11512 Track Cancel button tap
    }

    /// Invoked after the user selects a media source to add an image.
    /// - Parameter source: Source of the image.
    func addImage(from source: MediaPickingSource) {
        guard let onAddImage else {
            return
        }
        let previousState = imageState
        imageState = .loading
        Task { @MainActor in
            guard let image = await onAddImage(source) else {
                return imageState = previousState
            }
            imageState = .success(image)
        }
    }

    func didTapPrevious() {
        guard let selectedSuggestionIndex,
              selectedSuggestionIndex > 0 else {
            return
        }

        do {
            let newIndex = selectedSuggestionIndex - 1
            try selectSuggestion(at: newIndex)
            self.selectedSuggestionIndex = newIndex
        } catch {
            DDLogError("⛔️ Error selecting Blaze AI suggestion: \(error)")
        }
    }

    func didTapNext() {
        let newIndex = {
            guard let selectedSuggestionIndex else {
                // Select first item when no suggestion is selected previously
                return 0
            }


            guard selectedSuggestionIndex < suggestions.count - 1 else {
                // No more suggestions available to select
                return selectedSuggestionIndex
            }

            return selectedSuggestionIndex + 1
        }()

        do {
            try selectSuggestion(at: newIndex)
            selectedSuggestionIndex = newIndex
        } catch {
            DDLogError("⛔️ Error selecting Blaze AI suggestion: \(error)")
        }
    }
}

// MARK: Character length limit
extension BlazeEditAdViewModel {
    private func watchCharacterLimit() {
        $tagline
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self else { return }
                if text.count >= self.taglineMaxLength {
                    self.taglineRemainingLength = 0
                } else {
                    self.taglineRemainingLength = self.taglineMaxLength - text.count
                }

                taglineEmptyError = text.isEmpty ? Localization.taglineEmpty : nil
            }.store(in: &subscriptions)

        $description
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self else { return }
                if text.count >= self.descriptionMaxLength {
                    self.descriptionRemainingLength = 0
                } else {
                    self.descriptionRemainingLength = self.descriptionMaxLength - text.count
                }

                descriptionEmptyError = text.isEmpty ? Localization.descriptionEmpty : nil
            }.store(in: &subscriptions)
    }

    func formatTagline(_ newValue: String) -> String {
        guard newValue.count > taglineMaxLength else {
            return newValue
        }
        return String(newValue.prefix(taglineMaxLength))
    }

    func formatDescription(_ newValue: String) -> String {
        guard newValue.count > descriptionMaxLength else {
            return newValue
        }
        return String(newValue.prefix(descriptionMaxLength))
    }
}

// MARK: AI suggestion
private extension BlazeEditAdViewModel {
    func setSelectedSuggestionIfApplicable() {
        selectedSuggestionIndex = suggestions.firstIndex(where: { $0.siteName == tagline && $0.textSnippet == description})
    }

    func selectSuggestion(at index: Int) throws {
        guard let suggestion = suggestions[safe: index] else {
            throw AISuggestionError.noMatchingSuggestionFound
        }
        tagline = suggestion.siteName
        description = suggestion.textSnippet
    }
}

extension BlazeEditAdViewModel {
    enum Localization {
        enum LengthLimit {
            static let plural = NSLocalizedString(
                "blazeEditAdViewModel.lengthLimit.plural",
                value: "%1$d characters remaining",
                comment: "Edit Blaze Ad screen: Plural form text showing the max allowed characters length for Tagline or Description field." +
                " " +
                "%1$d is replaced with the remaining available characters count. Reads like: 10 characters remaining"
            )
            static let singular = NSLocalizedString(
                "blazeEditAdViewModel.lengthLimit.singular",
                value: "%1$d character remaining",
                comment: "Edit Blaze Ad screen: Singular form text showing the max allowed characters length for Tagline or Description field." +
                " " +
                "%1$d is replaced with the remaining available characters count. Reads like: 1 character remaining"
            )
        }
        static let taglineEmpty = NSLocalizedString(
            "blazeEditAdViewModel.tagline.emptyError",
            value: "Tagline cannot be empty",
            comment: "Edit Blaze Ad screen: Error message if Tagline field is empty."
        )
        static let descriptionEmpty = NSLocalizedString(
            "blazeEditAdViewModel.description.emptyError",
            value: "Description cannot be empty",
            comment: "Edit Blaze Ad screen: Error message if Description field is empty."
        )
    }
}

private enum AISuggestionError: Error {
    case noMatchingSuggestionFound
}
