import UniformTypeIdentifiers

/// Types of media.
///
public enum MediaType {
    case image
    case video
    case powerpoint
    case audio
    case other

    init(fileExtension: String) {
        guard let typeIdentifier = UTType(filenameExtension: fileExtension) else {
            self = .other
            return
        }
        self.init(dataType: typeIdentifier)
    }

    init(mimeType: String) {
        guard let typeIdentifier = UTType(mimeType: mimeType) else {
            self = .other
            return
        }
        self.init(dataType: typeIdentifier)
    }

    private init(dataType: UTType) {
        // Prior to iOS 14.4, video/webm and audio/webm were not natively supported and would
        // have resulted as `self = .other` in the code below. iOS 14.4 added support for them,
        // interpreting both as video types, but we don't want the app to allow users to upload
        // them because WooCommerce/WordPress don't support that format, yet.
        //
        // The UT type identifier for both video/webm and audio/webm is "org.webmproject.webm"
        //
        // See https://github.com/woocommerce/woocommerce-ios/pull/4459/files#r656194065
        guard dataType != UTType("org.webmproject.webm") else {
            self = .other
            return
        }

        if dataType.conforms(to: UTType.image) {
            self = .image
        } else if dataType.conforms(to: UTType.movie) {
            self = .video
        } else if dataType.conforms(to: UTType.presentation) {
            self = .powerpoint
        } else if dataType.conforms(to: UTType.audio) {
            self = .audio
        } else {
            self = .other
        }
    }
}
