import MobileCoreServices

/// Types of media.
///
public enum MediaType {
    case image
    case video
    case powerpoint
    case audio
    case other

    init(fileExtension: String) {
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        guard let fileUTI = unmanagedFileUTI?.takeRetainedValue() else {
            self = .other
            return
        }
        self.init(fileUTI: fileUTI)
    }

    init(mimeType: String) {
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
        guard let fileUTI = unmanagedFileUTI?.takeRetainedValue() else {
            self = .other
            return
        }
        self.init(fileUTI: fileUTI)
    }

    private init(fileUTI: CFString) {
        if UTTypeConformsTo(fileUTI, kUTTypeImage) {
            self = .image
        } else if UTTypeConformsTo(fileUTI, kUTTypeVideo) {
            self = .video
        } else if UTTypeConformsTo(fileUTI, kUTTypeMovie) {
            self = .video
        } else if UTTypeConformsTo(fileUTI, kUTTypeMPEG4) {
            self = .video
        } else if UTTypeConformsTo(fileUTI, kUTTypePresentation) {
            self = .powerpoint
        } else if UTTypeConformsTo(fileUTI, kUTTypeAudio) {
            self = .audio
        } else {
            self = .other
        }
    }
}
