import XCTest
import struct Networking.Note
@testable import WooCommerce

final class PushNotificationTests: XCTestCase {
    private let userInfo: [AnyHashable: Any] = [
        "blog": "205617935",
        // swiftlint:disable line_length
        "note_full_data": "eNqVkc1O6zAQhV/FjNiRH+enTZqHgA0bdI0qN522hsSx4jEFobz7nYRSwZJN7MjnfDpn5hPsQOih+fcJZg9NXUgpiyyrygjowyE04GkYcTuMexwhgmBH1Cy0oesi8NY4h/T92yNpaGaSnw9viAG5XK2zalOsIviCNIVcTxF0xr7+kMGJyPlGpSp1YdeZNtbOJGe2uBG9T9qhVynfSKVvmUpnk1fpFQ5X+h9Bi4tJHAomjuVJU/DXgmH3gi0t8yF85ws8DUGc9BsKLSyexeK/ESrs66Ll76HewBRd1fffEnEYRnGbJ1KKwQo6oVgGC9MzT9r0nEf3jg25zMtYVnG+fswkj6opizspGylh1lGHF+jDZSGmHeyv0j45u6+SZxfzI6Hlqn2IXReOxnLVZeUqNb0+zmdwe00YO/3RszTO3xNnj0xm2QWuwqEsqyVqpz1tPaLdzqH5Lavysi7qzaqYLaHfzTvIpv+sG8QM",
        "aps": [
            "category": "store_order",
            "badge": 1,
            "sound": "o.caf",
            "content-available": 1,
            "mutable-content": 1,
            "thread-id": "205617935 - store_order",
            "alert": [
                "body": "New order for $2.00 on the store",
                "title": "You have a new order! 🎉"
                ]
        ],
        "type": "store_order",
        "blog_id": "205617935",
        "note_id": "8326526386",
        "user": "212589093",
        "title": "You have a new order! 🎉",
        "content-available": 1,
        "mutable-content": 1
    ]

    func test_pushNotification_from_userInfo() {
        guard let notification = PushNotification.from(userInfo: userInfo) else {
            XCTFail("Created notification should not be nil")
            return
        }
        guard let note = notification.note else {
            XCTFail("Created notification should have a non nil note property")
            return
        }
        XCTAssertEqual(notification.noteID, Int64(8326526386))
        XCTAssertEqual(notification.title, "You have a new order! 🎉")
        XCTAssertEqual(notification.kind, Note.Kind.storeOrder)
        XCTAssertEqual(note.kind, Note.Kind.storeOrder)
        XCTAssertEqual(note.noteID, Int64(8300031174))
        XCTAssertEqual(note.icon, "https://s.wp.com/wp-content/mu-plugins/notes/images/update-payment-2x.png")
        XCTAssertEqual(note.type, "store_order")
        XCTAssertEqual(note.title, "New Order")
        XCTAssertEqual(note.meta.identifier(forKey: .order), 306)
    }
}
