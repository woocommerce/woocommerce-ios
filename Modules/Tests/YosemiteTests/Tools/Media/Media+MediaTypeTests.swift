import XCTest
@testable import Yosemite

final class Media_MediaTypeTests: XCTestCase {
    // MARK: - Image types

    func testGIFMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "gif", mimeType: "image/gif")
        XCTAssertEqual(media.mediaType, .image, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testJPGMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "jpg", mimeType: "image/jpeg")
        XCTAssertEqual(media.mediaType, .image, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testJPEGMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "jpeg", mimeType: "image/jpeg")
        XCTAssertEqual(media.mediaType, .image, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testPNGMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "png", mimeType: "image/png")
        XCTAssertEqual(media.mediaType, .image, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    // MARK: - Video types

    func testMP4MediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "mp4", mimeType: "video/mp4")
        XCTAssertEqual(media.mediaType, .video, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testMOVMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "mov", mimeType: "video/quicktime")
        XCTAssertEqual(media.mediaType, .video, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testM4VMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "m4v", mimeType: "video/mp4")
        XCTAssertEqual(media.mediaType, .video, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    // MARK: - Audio types

    func testWAVMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "wav", mimeType: "audio/wav")
        XCTAssertEqual(media.mediaType, .audio, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testMP3MediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "mp3", mimeType: "audio/mpeg")
        XCTAssertEqual(media.mediaType, .audio, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    // MARK: - Presentation types

    func testPPTMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "ppt", mimeType: "application/vnd.ms-powerpoint")
        XCTAssertEqual(media.mediaType, .powerpoint, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    // MARK: - Other types

    func testZIPMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "zip", mimeType: "application/zip")
        XCTAssertEqual(media.mediaType, .other, "Unexpected media type \(media.mediaType) for media: \(media)")
    }

    func testPDFMediaType() throws {
        try XCTSkipIf(testingOnRosetta())
        let media = createSampleMedia(fileExtension: "pdf", mimeType: "application/pdf")
        XCTAssertEqual(media.mediaType, .other, "Unexpected media type \(media.mediaType) for media: \(media)")
    }
}

private extension Media_MediaTypeTests {
    func createSampleMedia(fileExtension: String, mimeType: String) -> Media {
        return Media(mediaID: 2022,
                     date: Date(),
                     fileExtension: fileExtension,
                     filename: "",
                     mimeType: mimeType,
                     src: "",
                     thumbnailURL: nil,
                     name: nil,
                     alt: nil,
                     height: nil,
                     width: nil)
    }
}
