import Foundation

import Storage

/// Calculates whether the app should display the In-app Feedback Card to the user.
///
/// The result is only `true` if these conditions are met:
///
/// - The known installation date is more than 3 months ago
/// - The user has not given feedback for more than 6 months ago.
///
struct InAppFeedbackCardVisibilityUseCase {
    /// Errors returned by this UseCase.
    enum InferenceError: Error {
        case failedToInferInstallationDate
        case unexpectedCalendarResult
    }

    private let fileManager: FileManager
    private let calendar: Calendar

    private let settings: GeneralAppSettings
    private let feedbackType: FeedbackType

    init(settings: GeneralAppSettings, feedbackType: FeedbackType, fileManager: FileManager = FileManager.default, calendar: Calendar = .current) {
        self.settings = settings
        self.feedbackType = feedbackType
        self.fileManager = fileManager
        self.calendar = calendar
    }

    /// Returns whether the feedback request should be displayed.
    ///
    /// - Parameter currentDate The current date. This is only used for consistency in unit tests.
    ///
    func shouldBeVisible(currentDate: Date = Date()) throws -> Bool {
        switch feedbackType {
        case .general:
            return try shouldGeneralFeedbackBeVisible(currentDate: currentDate)
        case .productsM4:
            return shouldProductsFeedbackBeVisible()
        case .shippingLabelsRelease1:
            return shouldShippingLabelsRelease1FeedbackBeVisible()
        }
    }

    /// Returns whether the In-app Feedback Card should be displayed.
    ///
    private func shouldGeneralFeedbackBeVisible(currentDate: Date) throws -> Bool {
        guard let installationDate = inferInstallationDate() else {
            throw InferenceError.failedToInferInstallationDate
        }

        if try numberOfDays(from: installationDate, to: currentDate) < Constants.minimumInstallAgeInDays {
            return false
        }

        guard case let .given(lastFeedbackDate) = settings.feedbackStatus(of: feedbackType) else {
            return true
        }

        if try numberOfDays(from: lastFeedbackDate, to: currentDate) < Constants.feedbackFrequencyInDays {
            return false
        }

        return true
    }

    /// Returns whether the productsM4 feedback request should be displayed
    ///
    private func shouldProductsFeedbackBeVisible() -> Bool {
        return settings.feedbackStatus(of: feedbackType) == .pending
    }

    /// Returns whether the shippingLabelsRelease1 feedback request should be displayed
    ///
    private func shouldShippingLabelsRelease1FeedbackBeVisible() -> Bool {
        return settings.feedbackStatus(of: feedbackType) == .pending
    }

    /// Returns the total number of days between `from` and `to`.
    private func numberOfDays(from: Date, to: Date) throws -> Int {
        let components = [.day] as Set<Calendar.Component>
        let dateComponents = calendar.dateComponents(components, from: from, to: to)
        guard let days = dateComponents.day else {
            throw InferenceError.unexpectedCalendarResult
        }

        return days
    }

    /// Retrieve the installation date.
    ///
    /// Checks both the date of `GeneralAppSettings.installationDate` and the creation date of the
    /// Documents directory. The oldest of the two will be returned.
    ///
    /// We could simply just use the `GeneralAppSettings.installationDate` but we also have to
    /// consider the users who have already installed before we started tracking that value.
    ///
    private func inferInstallationDate() -> Date? {
        switch (creationDateOfDocumentDir(), settings.installationDate) {
            case let (documentDirCreationDate?, savedInstallationDate?):
                return min(documentDirCreationDate, savedInstallationDate)
            case let (documentDirCreationDate?, nil):
                return documentDirCreationDate
            case let (nil, savedInstallationDate?):
                return savedInstallationDate
            default:
                return nil
        }
    }

    /// Retrieve the date that the app's Documents directory was created.
    ///
    /// This value is used as a way to determine when the app was installed. There doesn't seem
    /// to be an API to check the true installation date.
    ///
    private func creationDateOfDocumentDir() -> Date? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last,
            let attributes = try? fileManager.attributesOfItem(atPath: documentsURL.path) else {
                return nil
        }

        return attributes[.creationDate] as? Date
    }
}

// MARK: - Constants

private extension InAppFeedbackCardVisibilityUseCase {
    enum Constants {
        /// The mininum number of days after the user has installed the app before we should
        /// ask for feedback.
        static let minimumInstallAgeInDays = 3 * 30
        /// The minimum number of days after the user's last feedback before we should ask
        /// for another feedback.
        static let feedbackFrequencyInDays = 6 * 30
    }
}
