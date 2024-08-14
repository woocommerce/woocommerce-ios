import Foundation
import protocol WooFoundation.Analytics
import struct Networking.BlazeAISuggestion

/// View model for `BlazeEditAdView`
final class BlazeEditAdViewModel: ObservableObject {
    typealias ImageState = EditableImageViewState

    let siteID: Int64
    let productID: Int64
    private let adData: BlazeEditAdData

    // Image selection
    var onAddImage: ((MediaPickingSource) async -> MediaPickerImage?)?
    @Published private(set) var imageState: ImageState
    var image: MediaPickerImage? {
        imageState.image
    }

    @Published var shouldDisplayImageSizeErrorAlert = false

    /// API expects the image dimensions to be minimum 400*400
    ///
    let minImageSize = CGSize(width: 400, height: 400)

    // Tagline
    @Published var tagline: String = ""
    var taglineFooterText: String {
        if tagline.isEmpty {
            Localization.taglineEmpty
        } else if tagline.count > Constants.taglineMaxLength {
            String.localizedStringWithFormat(Localization.taglineLengthExceedsLimit, Constants.taglineMaxLength)
        } else {
            taglineLengthLimitLabel
        }
    }

    var isTaglineValidated: Bool {
        tagline.isNotEmpty && tagline.count <= Constants.taglineMaxLength
    }

    @Published private var taglineRemainingLength: Int
    private var taglineLengthLimitLabel: String {
        let lengthText = String.pluralize(taglineRemainingLength,
                                          singular: Localization.LengthLimit.singular,
                                          plural: Localization.LengthLimit.plural)
        return String(format: lengthText, taglineRemainingLength)
    }

    // Description
    @Published var description: String = ""
    var descriptionFooterText: String {
        if description.isEmpty {
            Localization.descriptionEmpty
        } else if description.count > Constants.descriptionMaxLength {
            String.localizedStringWithFormat(Localization.descriptionLengthExceedsLimit, Constants.descriptionMaxLength)
        } else {
            descriptionLengthLimitLabel
        }
    }

    var isDescriptionValidated: Bool {
        description.isNotEmpty && description.count <= Constants.descriptionMaxLength
    }

    @Published private var descriptionRemainingLength: Int
    private var descriptionLengthLimitLabel: String {
        let lengthText = String.pluralize(descriptionRemainingLength,
                                          singular: Localization.LengthLimit.singular,
                                          plural: Localization.LengthLimit.plural)
        return String(format: lengthText, descriptionRemainingLength)
    }

    var isSaveButtonEnabled: Bool {
        guard let editedAdData,
                taglineRemainingLength >= 0,
                descriptionRemainingLength >= 0 else {
            return false
        }

        return editedAdData != adData
    }

    private var editedAdData: BlazeEditAdData? {
        guard tagline.isNotEmpty,
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

    init(siteID: Int64,
         productID: Int64,
         adData: BlazeEditAdData,
         suggestions: [BlazeAISuggestion],
         analytics: Analytics = ServiceLocator.analytics,
         onSave: @escaping (BlazeEditAdData) -> Void) {
        self.siteID = siteID
        self.productID = productID

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
        self.taglineRemainingLength = Constants.taglineMaxLength
        self.descriptionRemainingLength = Constants.descriptionMaxLength

        watchCharacterLimit()
        setSelectedSuggestionIfApplicable()
    }

    func didTapSave() {
        analytics.track(event: .Blaze.EditAd.saveTapped())
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
            guard image.image.size.width * image.image.scale >= minImageSize.width && image.image.size.height * image.image.scale >= minImageSize.height else {
                shouldDisplayImageSizeErrorAlert = true
                return imageState = previousState
            }
            imageState = .success(image)
        }
    }

    func didTapPrevious() {
        analytics.track(event: .Blaze.EditAd.aiSuggestionTapped())

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
        analytics.track(event: .Blaze.EditAd.aiSuggestionTapped())

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
            .map { text -> Int in
                Constants.taglineMaxLength - text.count
            }
            .assign(to: &$taglineRemainingLength)

        $description
            .map { text -> Int in
                Constants.descriptionMaxLength - text.count
            }
            .assign(to: &$descriptionRemainingLength)
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
    enum Constants {
        static let taglineMaxLength = 32
        static let descriptionMaxLength = 140
    }

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
        static let taglineLengthExceedsLimit = NSLocalizedString(
            "blazeEditAdViewModel.tagline.lengthExceedsLimit",
            value: "Tagline cannot exceed %1$d characters",
            comment: "Edit Blaze Ad screen: Error message if Tagline exceeds the character limit."
        )
        static let descriptionLengthExceedsLimit = NSLocalizedString(
            "blazeEditAdViewModel.description.lengthExceedsLimit",
            value: "Description cannot exceed %1$d characters",
            comment: "Edit Blaze Ad screen: Error message if Description exceeds the character limit."
        )
    }
}

private enum AISuggestionError: Error {
    case noMatchingSuggestionFound
}
