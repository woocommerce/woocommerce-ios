import UIKit
import Testing
import Yosemite
@testable import WooCommerce

struct CancellableMediaWPMediaAssetTests {
    @Test func image_when_media_id_exceeds_int32_then_returns_a_request_id_without_trapping() {
        // Given
        let media = Media.fake().copy(mediaID: Int64(Int32.max) + 1,
                                      src: "https://example.com/image.jpg",
                                      thumbnailURL: "https://example.com/image-150x150.jpg")
        let cancellableMedia = CancellableMedia(media: media)

        // When
        let requestID = cancellableMedia.image(with: CGSize(width: 100, height: 100)) { _, _ in }

        // Then
        #expect(requestID != 0)
    }
}
