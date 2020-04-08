import XCTest
@testable import Yosemite

final class MediaTypeTests: XCTestCase {
    // MARK: - `init(fileExtension: String)`
    // Reference: https://wordpress.com/support/accepted-filetypes/

    func testInitWithImageFileExtensions() {
        let imageFileExtensions = ["jpg", "jpeg", "gif", "png"]
        imageFileExtensions.forEach { fileExtension in
            XCTAssertEqual(MediaType(fileExtension: fileExtension), .image, "Unexpected media type for file extension: \(fileExtension)")
        }
    }

    func testInitWithVideoFileExtensions() {
        // Note: "ogv" isn't supported on iOS.
        let videoFileExtensions = ["mp4", "m4v", "mov", "wmv", "avi", "mpg", "3gp", "3g2"]
        videoFileExtensions.forEach { fileExtension in
            XCTAssertEqual(MediaType(fileExtension: fileExtension), .video, "Unexpected media type for file extension: \(fileExtension)")
        }
    }

    func testInitWithAudioFileExtensions() {
        // Note: "ogg" isn't supported on iOS.
        let audioFileExtensions = ["mp3", "m4a", "wav"]
        audioFileExtensions.forEach { fileExtension in
            XCTAssertEqual(MediaType(fileExtension: fileExtension), .audio, "Unexpected media type for file extension: \(fileExtension)")
        }
    }

    func testInitWithPowerpointFileExtensions() {
        let presentationFileExtensions = ["ppt", "pptx", "pps", "ppsx"]
        presentationFileExtensions.forEach { fileExtension in
            XCTAssertEqual(MediaType(fileExtension: fileExtension), .powerpoint, "Unexpected media type for file extension: \(fileExtension)")
        }
    }

    func testInitWithOtherFileExtensions() {
        let presentationFileExtensions = [
            "pdf", "doc", "odt", "xls", "xlsx",
            // Audio/video formats that are not supported on iOS
            "ogg", "ogv"
        ]
        presentationFileExtensions.forEach { fileExtension in
            XCTAssertEqual(MediaType(fileExtension: fileExtension), .other, "Unexpected media type for file extension: \(fileExtension)")
        }
    }

    // MARK: - `init(mimeType: String)`
    // References:
    // - Common MIME types compiled by Mozilla:
    //   https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
    // - IANA, the official registry of MIME media types and maintains a list of all the official MIME types:
    //   http://www.iana.org/assignments/media-types/media-types.xhtml

    func testInitWithImageMimeType() {
        let imageMimeTypes = ["image/jpeg", "image/gif", "image/png"]
        imageMimeTypes.forEach { mimeType in
            XCTAssertEqual(MediaType(mimeType: mimeType), .image, "Unexpected media type for file extension: \(mimeType)")
        }
    }

    func testInitWithVideoMimeType() {
        let videoMimeTypes = [
            "video/mp4", "video/x-msvideo", "video/mpeg", "video/3gpp", "video/3gpp2",
            // 3gpp/3gpp2 audio is considered as video on iOS
            "audio/3gpp", "audio/3gpp2"
        ]
        videoMimeTypes.forEach { mimeType in
            XCTAssertEqual(MediaType(mimeType: mimeType), .video, "Unexpected media type for file extension: \(mimeType)")
        }
    }

    func testInitWithAudioMimeType() {
        let audioMimeTypes = ["audio/midi", "audio/x-midi", "audio/mpeg", "audio/wav"]
        audioMimeTypes.forEach { mimeType in
            XCTAssertEqual(MediaType(mimeType: mimeType), .audio, "Unexpected media type for file extension: \(mimeType)")
        }
    }

    func testInitWithPowerpointMimeType() {
        let presentationMimeTypes = ["application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation"]
        presentationMimeTypes.forEach { mimeType in
            XCTAssertEqual(MediaType(mimeType: mimeType), .powerpoint, "Unexpected media type for file extension: \(mimeType)")
        }
    }

    func testInitWithOtherMimeType() {
        let otherMimeTypes = [
            "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.oasis.opendocument.text", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            // Video formats that are not supported on iOS
            "video/ogg", "video/mp2t", "video/webm",
            // Audio formats that are not supported on iOS
            "audio/ogg", "audio/opus", "audio/webm"
        ]
        otherMimeTypes.forEach { mimeType in
            XCTAssertEqual(MediaType(mimeType: mimeType), .other, "Unexpected media type for file extension: \(mimeType)")
        }
    }
}
