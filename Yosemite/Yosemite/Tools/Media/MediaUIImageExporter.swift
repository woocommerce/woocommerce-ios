import Foundation

/// Exports a media item of `UIImage` type to be uploadable.
///
final class MediaUIImageExporter: MediaExporter {

    let mediaDirectoryType: MediaDirectory

    private let image: UIImage
    private let imageOptions: MediaImageExportOptions
    private let filename: String
    private let altText: String?

    init(image: UIImage,
         imageOptions: MediaImageExportOptions,
         filename: String?,
         altText: String?,
         mediaDirectoryType: MediaDirectory = .uploads) {
        self.image = image
        self.imageOptions = imageOptions
        self.filename = filename ?? UUID().uuidString + ".jpg"
        self.altText = altText
        self.mediaDirectoryType = mediaDirectoryType
    }

    func export() throws -> UploadableMedia {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            throw ExportError.cannotConvertToJPEG
        }

        // Hands off the image export to a shared image writer.
        let exporter = MediaImageExporter(data: imageData,
                                          filename: filename,
                                          altText: altText,
                                          typeHint: nil,
                                          options: imageOptions,
                                          mediaDirectoryType: mediaDirectoryType)
        return try exporter.export()
    }
}

extension MediaUIImageExporter {
    enum ExportError: Error {
        case cannotConvertToJPEG
    }
}
