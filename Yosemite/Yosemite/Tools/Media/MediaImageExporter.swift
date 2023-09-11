import Foundation
import UniformTypeIdentifiers
import MobileCoreServices

/// Available options for an image export.
///
struct MediaImageExportOptions {
    /// Set a maximumImageSize for resizing images, or nil for exporting the full images.
    ///
    let maximumImageSize: CGFloat?

    /// Compression quality if the image type supports compression, defaults to no compression or maximum quality.
    ///
    let imageCompressionQuality: Double

    /// If the original asset contains geo location information, enabling this option will remove it.
    let stripsGeoLocationIfNeeded: Bool

    init(maximumImageSize: CGFloat?,
         imageCompressionQuality: Double,
         stripsGeoLocationIfNeeded: Bool) {
        self.maximumImageSize = maximumImageSize
        self.imageCompressionQuality = imageCompressionQuality
        self.stripsGeoLocationIfNeeded = stripsGeoLocationIfNeeded
    }
}

/// Media export handling of UIImages.
///
final class MediaImageExporter: MediaExporter {

    let mediaDirectoryType: MediaDirectory

    /// Export options.
    ///
    private let options: MediaImageExportOptions

    /// Default filename used when writing media images locally, which may be appended with "-1" or "-thumbnail".
    ///
    private let defaultImageFilename = "image"

    private let data: Data
    private let filename: String?
    private let altText: String?
    private let typeHint: String?

    private let imageSourceWriter: ImageSourceWriter

    init(data: Data,
         filename: String?,
         altText: String?,
         typeHint: String? = nil,
         options: MediaImageExportOptions,
         mediaDirectoryType: MediaDirectory = .uploads,
         imageSourceWriter: ImageSourceWriter = DefaultImageSourceWriter()) {
        self.filename = filename
        self.altText = altText
        self.data = data
        self.typeHint = typeHint
        self.options = options
        self.mediaDirectoryType = mediaDirectoryType
        self.imageSourceWriter = imageSourceWriter
    }

    func export() throws -> UploadableMedia {
        try exportImage(data: data, fileName: filename, altText: altText, typeHint: typeHint)
    }

    /// Exports and writes an image's data, expected as PNG or JPEG format, to a local Media URL.
    ///
    /// - Parameters:
    ///     - data: Image data.
    ///     - fileName: Filename if it's known.
    ///     - typeHint: The UTType of data, if it's known. It is used as the preferred type.
    ///
    private func exportImage(data: Data,
                             fileName: String?,
                             altText: String?,
                             typeHint: String?) throws -> UploadableMedia {
        do {
            let hint = typeHint ?? UTType.jpeg.identifier
            let sourceOptions: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: hint as CFString]
            guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
                throw ImageExportError.imageSourceCreationWithDataFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ImageExportError.imageSourceIsAnUnknownType
            }
            return try exportImageSource(source,
                                         filename: fileName,
                                         altText: altText,
                                         type: typeHint ?? utType as String)
        } catch {
            throw error
        }
    }

    /// Exports and writes an image source to a local Media URL.
    ///
    /// - Parameters:
    ///     - fileName: Filename if it's known.
    ///
    /// - Returns: a progress object that report the current state of the export process.
    ///
    private func exportImageSource(_ source: CGImageSource,
                                   filename: String?,
                                   altText: String?,
                                   type: String) throws -> UploadableMedia {
        do {
            let filename = filename ?? defaultImageFilename
            // Makes a new URL within the local Media directory
            let url = try mediaFileManager.createLocalMediaURL(filename: filename,
                                                               fileExtension: URL.fileExtensionForUTType(type))

            _ = try imageSourceWriter.writeImageSource(source, to: url, sourceUTType: type as CFString, options: options)

            let exported = UploadableMedia(localURL: url,
                                           filename: url.lastPathComponent,
                                           mimeType: url.mimeTypeForPathExtension,
                                           altText: altText)
            return exported
        } catch {
            throw error
        }
    }
}

extension MediaImageExporter {
    enum ImageExportError: Error {
        case imageSourceCreationWithDataFailed
        case imageSourceIsAnUnknownType

        var description: String {
            switch self {
            default:
                return NSLocalizedString("The image could not be added to the Media Library.",
                                         comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            }
        }
    }
}
