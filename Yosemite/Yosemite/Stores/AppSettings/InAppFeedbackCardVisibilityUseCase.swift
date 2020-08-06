import Foundation

import Storage

struct InAppFeedbackCardVisibilityUseCase {
    enum InferenceError: Error {
        case failedToInferInstallationDate
        case unexpectedCalendarResult
    }

    private let fileManager: FileManager
    private let calendar: Calendar

    private let settings: GeneralAppSettings

    init(settings: GeneralAppSettings, fileManager: FileManager = FileManager.default, calendar: Calendar = .current) {
        self.settings = settings
        self.fileManager = fileManager
        self.calendar = calendar
    }

    func shouldBeVisible(currentDate: Date = Date()) throws -> Bool {
        guard let installationDate = inferInstallationDate() else {
            throw InferenceError.failedToInferInstallationDate
        }

        if try numberOfDays(from: installationDate, to: currentDate) < Constants.minimumInstallAgeInDays {
            return false
        }

        guard let lastFeedbackDate = settings.lastFeedbackDate else {
            return true
        }

        if try numberOfDays(from: lastFeedbackDate, to: currentDate) < Constants.feedbackFrequencyInDays {
            return false
        }

        return true
    }

    private func numberOfDays(from: Date, to: Date) throws -> Int {
        let components = [.day] as Set<Calendar.Component>
        let dateComponents = calendar.dateComponents(components, from: from, to: to)
        guard let days = dateComponents.day else {
            throw InferenceError.unexpectedCalendarResult
        }

        return days
    }

    private func inferInstallationDate() -> Date? {
        let documentDirCreationDate = creationDateOfDocumentDir()
        let savedInstallationDate = settings.installationDate

        if let documentDirCreationDate = documentDirCreationDate,
            let savedInstallationDate = savedInstallationDate {
            return min(documentDirCreationDate, savedInstallationDate)
        } else if documentDirCreationDate != nil {
            return documentDirCreationDate
        } else if savedInstallationDate != nil {
            return savedInstallationDate
        } else {
            return nil
        }
    }

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
        static let minimumInstallAgeInDays = 3 * 30
        static let feedbackFrequencyInDays = 6 * 30
    }
}
