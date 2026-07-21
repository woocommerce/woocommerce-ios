import Foundation

/// Composes the complete attachment list for a Zendesk support request.
protocol SupportRequestAttachmentProviding {
    func attachments(including attachments: [ZendeskAttachment]) -> [ZendeskAttachment]
}

/// Appends the full application log to support-request attachments when available.
final class DefaultSupportRequestAttachmentProvider: SupportRequestAttachmentProviding {
    private enum Constants {
        static let applicationLogFilename = "application_log.txt"
        static let plainTextContentType = "text/plain"
    }

    private let applicationLogProvider: ApplicationLogProvider

    init(applicationLogProvider: ApplicationLogProvider = ServiceLocator.applicationLogProvider) {
        self.applicationLogProvider = applicationLogProvider
    }

    func attachments(including attachments: [ZendeskAttachment]) -> [ZendeskAttachment] {
        guard attachments.contains(where: { $0.filename == Constants.applicationLogFilename }) == false,
              let applicationLogs = applicationLogProvider.applicationLogs(),
              applicationLogs.isNotEmpty,
              let applicationLogData = applicationLogs.data(using: .utf8) else {
            return attachments
        }

        return attachments + [ZendeskAttachment(data: applicationLogData,
                                                filename: Constants.applicationLogFilename,
                                                contentType: Constants.plainTextContentType)]
    }
}
