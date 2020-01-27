@testable import Yosemite

final class MockupImageSourceWriter: ImageSourceWriter {
    var url: URL?

    func writeImageSource(_ source: CGImageSource,
                          to url: URL,
                          sourceUTType: CFString,
                          options: MediaImageExportOptions) throws -> ImageSourceWriteResultProperties {
        self.url = url
        return ImageSourceWriteResultProperties(width: nil, height: nil)
    }
}
