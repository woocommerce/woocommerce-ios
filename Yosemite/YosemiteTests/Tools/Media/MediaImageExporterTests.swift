import MobileCoreServices
import XCTest
@testable import Yosemite

final class MediaImageExporterTests: XCTestCase {
    func testExportingAnImageWithTypeHint() {
        let mockData = UIImage(named: "image", in: Bundle(for: type(of: self)), compatibleWith: nil)!.pngData()
        let filename = "test"
        let typeHint = kUTTypeJPEG as String
        let mockImageSourceWriter = MockupImageSourceWriter()
        let exporter = MediaImageExporter(data: mockData!,
                                          filename: filename,
                                          typeHint: typeHint,
                                          options: MediaImageExportOptions(maximumImageSize: nil,
                                                                           imageCompressionQuality: 1.0,
                                                                           stripsGeoLocationIfNeeded: true),
                                          mediaDirectoryType: .temporary,
                                          imageSourceWriter: mockImageSourceWriter)

        do {
            let expectedImageURL = try exporter.mediaFileManager
                .createLocalMediaURL(filename: filename,
                                     fileExtension: URL.fileExtensionForUTType(typeHint))
            let expectation = self.expectation(description: "Export image data")
            exporter.export { (uploadableMedia, error) in
                XCTAssertEqual(mockImageSourceWriter.targetURL, expectedImageURL)
                expectation.fulfill()
            }
            waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testExportingAnImageWithoutTypeHint() {
        let mockData = UIImage(named: "image", in: Bundle(for: type(of: self)), compatibleWith: nil)!.pngData()
        let filename = "test"
        let mockImageSourceWriter = MockupImageSourceWriter()
        let exporter = MediaImageExporter(data: mockData!,
                                          filename: filename,
                                          typeHint: nil,
                                          options: MediaImageExportOptions(maximumImageSize: nil,
                                                                           imageCompressionQuality: 1.0,
                                                                           stripsGeoLocationIfNeeded: true),
                                          mediaDirectoryType: .temporary,
                                          imageSourceWriter: mockImageSourceWriter)

        do {
            let expectedImageURL = try exporter.mediaFileManager
                .createLocalMediaURL(filename: filename,
                                     fileExtension: "png")
            let expectation = self.expectation(description: "Export image data")
            exporter.export { (uploadableMedia, error) in
                XCTAssertEqual(mockImageSourceWriter.targetURL, expectedImageURL)
                expectation.fulfill()
            }
            waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testExportingNonImageData() {
        let mockData = Data()
        let filename = "test"
        let typeHint = kUTTypeJPEG as String
        let mockImageSourceWriter = MockupImageSourceWriter()
        let exporter = MediaImageExporter(data: mockData,
                                          filename: filename,
                                          typeHint: typeHint,
                                          options: MediaImageExportOptions(maximumImageSize: nil,
                                                                           imageCompressionQuality: 1.0,
                                                                           stripsGeoLocationIfNeeded: true),
                                          mediaDirectoryType: .temporary,
                                          imageSourceWriter: mockImageSourceWriter)

        let expectation = self.expectation(description: "Export image data")
        exporter.export { (uploadableMedia, error) in
            XCTAssertEqual(error as? MediaImageExporter.ImageExportError, .imageSourceIsAnUnknownType)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}
