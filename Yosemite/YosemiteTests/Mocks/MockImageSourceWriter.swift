@testable import Yosemite

final class MockImageSourceWriter: ImageSourceWriter {
    private(set) var targetURL: URL?

    func writeImageSource(_ source: CGImageSource,
                          to url: URL,
                          sourceUTType: CFString,
                          options: MediaImageExportOptions) throws {
        self.targetURL = url
    }
}
