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
        // Prior to iOS 14.4, video/webm and audio/webm were not natively supported and would
        // have resulted as `self = .other` in the code below. iOS 14.4 added support for them,
        // interpreting both as video types, but we don't want the app to allow users to upload
        // them because WooCommerce/WordPress don't support that format, yet.
        //
        // The UT type identifier for both video/webm and audio/webm is "org.webmproject.webm"
        //
        // See https://github.com/woocommerce/woocommerce-ios/pull/4459/files#r656194065
        guard "\(fileUTI)" != "org.webmproject.webm" else {
            self = .other
            return
        }

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
