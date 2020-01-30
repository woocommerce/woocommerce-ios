import Foundation
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
    private let typeHint: String?

    private let imageSourceWriter: ImageSourceWriter

    init(data: Data,
         filename: String?,
         typeHint: String? = nil,
         options: MediaImageExportOptions,
         mediaDirectoryType: MediaDirectory = .uploads,
         imageSourceWriter: ImageSourceWriter = DefaultImageSourceWriter()) {
        self.filename = filename
        self.data = data
        self.typeHint = typeHint
        self.options = options
        self.mediaDirectoryType = mediaDirectoryType
        self.imageSourceWriter = imageSourceWriter
    }

    func export(onCompletion: @escaping MediaExportCompletion) {
        exportImage(data: data, fileName: filename, typeHint: typeHint, onCompletion: onCompletion)
    }

    /// Exports and writes an image's data, expected as PNG or JPEG format, to a local Media URL.
    ///
    /// - Parameters:
    ///     - data: Image data.
    ///     - fileName: Filename if it's known.
    ///     - typeHint: The UTType of data, if it's known. It is used as the preferred type.
    ///     - onCompletion: Called when the image export completes.
    ///
    private func exportImage(data: Data,
                             fileName: String?,
                             typeHint: String?,
                             onCompletion: @escaping MediaExportCompletion) {
        do {
            let hint = typeHint ?? kUTTypeJPEG as String
            let sourceOptions: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: hint as CFString]
            guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
                throw ImageExportError.imageSourceCreationWithDataFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ImageExportError.imageSourceIsAnUnknownType
            }
            exportImageSource(source,
                              filename: fileName,
                              type: typeHint ?? utType as String,
                              onCompletion: onCompletion)
        } catch {
            onCompletion(nil, error)
        }
    }

    /// Exports and writes an image source to a local Media URL.
    ///
    /// - Parameters:
    ///     - fileName: Filename if it's known.
    ///     - onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    ///     - onError: Called if an error was encountered during creation.
    ///
    /// - Returns: a progress object that report the current state of the export process.
    ///
    private func exportImageSource(_ source: CGImageSource,
                                   filename: String?,
                                   type: String,
                                   onCompletion: @escaping MediaExportCompletion) {
        do {
            let filename = filename ?? defaultImageFilename
            // Makes a new URL within the local Media directory
            let url = try mediaFileManager.createLocalMediaURL(filename: filename,
                                                               fileExtension: URL.fileExtensionForUTType(type))

            _ = try imageSourceWriter.writeImageSource(source, to: url, sourceUTType: type as CFString, options: options)

            let exported = UploadableMedia(localURL: url,
                                           filename: url.lastPathComponent,
                                           mimeType: url.mimeTypeForPathExtension)
            onCompletion(exported, nil)
        } catch {
            onCompletion(nil, error)
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
