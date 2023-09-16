import MobileCoreServices
import XCTest
import UniformTypeIdentifiers
@testable import Yosemite

final class MediaImageExporterTests: XCTestCase {
    func testExportingAnImageWithTypeHint() throws {
        // Loads the test image into png data.
        let mockData = UIImage(named: "image", in: Bundle(for: type(of: self)), compatibleWith: nil)!.pngData()
        let filename = "test"
        let typeHint = UTType.jpeg.identifier
        let mockImageSourceWriter = MockImageSourceWriter()
        let exporter = MediaImageExporter(data: mockData!,
                                          filename: filename,
                                          altText: nil,
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
            let _ = try exporter.export()
            XCTAssertEqual(mockImageSourceWriter.targetURL, expectedImageURL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testExportingAnImageWithAnUnknownTypeHintUsesTheImageDataType() throws {
        // Loads the test image into png data.
        let mockData = UIImage(named: "image", in: Bundle(for: type(of: self)), compatibleWith: nil)!.pngData()
        let filename = "test"
        let mockImageSourceWriter = MockImageSourceWriter()
        let exporter = MediaImageExporter(data: mockData!,
                                          filename: filename,
                                          altText: nil,
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
            let _ = try exporter.export()
            XCTAssertEqual(mockImageSourceWriter.targetURL, expectedImageURL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testExportingNonImageData() throws {
        let mockData = Data()
        let filename = "test"
        let typeHint = UTType.jpeg.identifier
        let mockImageSourceWriter = MockImageSourceWriter()
        let exporter = MediaImageExporter(data: mockData,
                                          filename: filename,
                                          altText: nil,
                                          typeHint: typeHint,
                                          options: MediaImageExportOptions(maximumImageSize: nil,
                                                                           imageCompressionQuality: 1.0,
                                                                           stripsGeoLocationIfNeeded: true),
                                          mediaDirectoryType: .temporary,
                                          imageSourceWriter: mockImageSourceWriter)

        do {
            let _ = try exporter.export()
        } catch {
            XCTAssertEqual(error as? MediaImageExporter.ImageExportError, .imageSourceIsAnUnknownType)
        }
    }

    func test_export_sets_filename_and_altText_in_output_media() throws {
        // Loads the test image into png data.
        let mockData = UIImage(named: "image", in: Bundle(for: type(of: self)), compatibleWith: nil)!.pngData()
        let exporter = MediaImageExporter(data: mockData!,
                                          filename: "test.png",
                                          altText: "cool-image",
                                          typeHint: nil,
                                          options: MediaImageExportOptions(maximumImageSize: nil,
                                                                           imageCompressionQuality: 1.0,
                                                                           stripsGeoLocationIfNeeded: true),
                                          mediaDirectoryType: .temporary,
                                          imageSourceWriter: MockImageSourceWriter())

        do {
            let media = try exporter.export()
            XCTAssertEqual(media.filename, "test.png")
            XCTAssertEqual(media.altText, "cool-image")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
