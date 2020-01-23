/// Writes an image to a URL from a CGImageSource, via CGImageDestination, particular to the needs of a `MediaImageExporter`.
///
struct ImageSourceWriter {

    /// File URL where the image should be written.
    ///
    private let url: URL

    /// The UTType of the image source.
    ///
    private let sourceUTType: CFString

    init(url: URL, sourceUTType: CFString) {
        self.url = url
        self.sourceUTType = sourceUTType
    }

    /// Struct for returned result from writing an image, and any properties worth keeping track of.
    ///
    struct WriteResultProperties {
        let width: CGFloat?
        let height: CGFloat?
    }

    /// Write a given image source, succeeds unless an error is thrown, returns the resulting properties if available.
    ///
    func writeImageSource(_ source: CGImageSource, options: MediaImageExportOptions) throws -> WriteResultProperties {
        // Create the destination with the URL, or error
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, sourceUTType, 1, nil) else {
            throw ImageSourceWriterError.imageSourceDestinationWithURLFailed
        }

        // Configure image properties for the image source and image destination methods
        // Preserve any existing properties from the source.
        var imageProperties: [NSString: Any] = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary) ?? [:]
        // Configure destination properties
        imageProperties[kCGImageDestinationLossyCompressionQuality] = options.imageCompressionQuality

        // Keep track of the image's width and height
        var width: CGFloat?
        var height: CGFloat?

        // Configure orientation properties to default .up or 1
        imageProperties[kCGImagePropertyOrientation] = Int(CGImagePropertyOrientation.up.rawValue) as CFNumber
        if var tiffProperties = imageProperties[kCGImagePropertyTIFFDictionary] as? [NSString: Any] {
            // Remove TIFF orientation value
            tiffProperties.removeValue(forKey: kCGImagePropertyTIFFOrientation)
            imageProperties[kCGImagePropertyTIFFDictionary] = tiffProperties
        }
        if var iptcProperties = imageProperties[kCGImagePropertyIPTCDictionary] as? [NSString: Any] {
            // Remove IPTC orientation value
            iptcProperties.removeValue(forKey: kCGImagePropertyIPTCImageOrientation)
            imageProperties[kCGImagePropertyIPTCDictionary] = iptcProperties
        }

        // Configure options for generating the thumbnail, such as the maximum size.
        var thumbnailOptions: [NSString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCache: false,
            kCGImageSourceTypeIdentifierHint: sourceUTType,
            kCGImageSourceCreateThumbnailWithTransform: true ]

        if let maximumSize = options.maximumImageSize {
            thumbnailOptions[kCGImageSourceThumbnailMaxPixelSize] = maximumSize as CFNumber
        }

        // Create a thumbnail of the image source.
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw ImageSourceWriterError.imageSourceThumbnailGenerationFailed
        }

        if options.stripsGeoLocationIfNeeded == true {
            // When removing GPS data for a thumbnail, we have to remove the dictionary
            // itself for the CGImageDestinationAddImage method.
            imageProperties.removeValue(forKey: kCGImagePropertyGPSDictionary)
        }

        // Add the thumbnail image as the destination's image.
        CGImageDestinationAddImage(destination, image, imageProperties as CFDictionary?)

        // Get the dimensions from the CGImage itself
        width = CGFloat(image.width)
        height = CGFloat(image.height)

        // Write the image to the file URL
        let written = CGImageDestinationFinalize(destination)
        guard written == true else {
            throw ImageSourceWriterError.imageSourceDestinationWriteFailed
        }

        // Return the result with any interesting properties.
        return WriteResultProperties(width: width,
                                     height: height)
    }
}

extension ImageSourceWriter {
    enum ImageSourceWriterError: Error {
        case imageSourceDestinationWithURLFailed
        case imageSourceThumbnailGenerationFailed
        case imageSourceDestinationWriteFailed
        var description: String {
            switch self {
            default:
                return NSLocalizedString("The image could not be added to the Media Library.",
                                         comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            }
        }
    }
}
