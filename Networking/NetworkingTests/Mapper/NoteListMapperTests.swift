import XCTest
@testable import Networking


/// NoteListMapperTests Unit Tests
///
final class NoteListMapperTests: XCTestCase {

    /// Sample Notes: 99 Entries!
    ///
    private lazy var sampleNotes: [Note] = {
        return try! mapLoadAllNotificationsResponse()
    }()


    /// Broken Notes: 2 (Hopefully gracefully handled) Scenarios.
    ///
    private lazy var brokenNotes: [Note] = {
        return try! mapLoadBrokenNotificationsResponse()
    }()



    /// Verifies that all of the Sample Notifications are properly parsed.
    ///
    func test_sample_notifications_are_properly_decoded() {
        XCTAssertEqual(sampleNotes.count, MockNetwork.notificationLoadAllJSONCount)
    }

    /// Verifies that the Broken Notification documents are properly parsed.
    ///
    func test_broken_notifications_are_gracefully_handled() {
        XCTAssertEqual(brokenNotes.count, 2)
    }

    /// Verifies that all of the plain Notification fields are parsed correctly.
    ///
    func test_sample_notification_gets_all_of_its_plain_fields_properly_parsed() {
        // Sample Note: Zero
        let note = sampleNotes[0]

        // Plain Fields
        XCTAssertEqual(note.noteID, 100001)
        XCTAssertEqual(note.hash, 987654)
        XCTAssertEqual(note.read, false)
        XCTAssert(note.icon == "https://gravatar.tld/some-hash")
        XCTAssert(note.noticon == "\u{f408}")
        XCTAssertEqual(note.timestamp, "2018-10-22T12:00:00+00:00")
        XCTAssertEqual(note.type, "comment_like")
        XCTAssertEqual(note.kind, .commentLike)
        XCTAssert(note.url == "https://someurl.sometld")
        XCTAssert(note.title == "3 Likes")

        // Blocks
        XCTAssertEqual(note.subject.count, 1)
        XCTAssertEqual(note.header.count, 2)
        XCTAssertEqual(note.body.count, 3)

        // Meta
        XCTAssertEqual(note.meta.identifier(forKey: .site), 123456)
        XCTAssertEqual(note.meta.identifier(forKey: .post), 2996)
        XCTAssertEqual(note.meta.link(forKey: .post), "https://public-someurl.sometld")
    }

    /// Verifies that the Timestamp is properly mapped into a Swift Date
    ///
    func test_sample_notification_gets_its_date_properly_converted_into_a_swift_date() {
        // Sample Note: Zero
        let note = sampleNotes[0]

        // Decompose!
        let components = [.day, .month, .year, .hour, .minute, .second] as Set<Calendar.Component>
        let dateComponents = Calendar.current.dateComponents(components, from: note.timestampAsDate)

        XCTAssertEqual(dateComponents.day, 22)
        XCTAssertEqual(dateComponents.month, 10)
        XCTAssertEqual(dateComponents.year, 2018)
    }

    /// Verifies that a broken Notifications document is "Gracefully handled". This means that:
    ///   - Default values are set
    ///   - Faulty encoded types are processed correctly (anyways)
    ///   - Parsing does not break completely for a broken nested entity.
    ///
    func test_broken_notification_gets_default_values_set() {
        // Broken Note: Zero
        let note = brokenNotes[0]

        // Plain Fields
        XCTAssertEqual(note.noteID, 123456)
        XCTAssertEqual(note.hash, 987654)
        XCTAssertFalse(note.read)
        XCTAssertNil(note.icon)
        XCTAssertNil(note.noticon)
        XCTAssertEqual(note.timestamp, "1234")
        XCTAssertEqual(note.kind, .unknown)
        XCTAssertNil(note.url)

        // Blocks
        XCTAssertEqual(note.subject.count, 1)
        XCTAssertEqual(note.header.count, 2)
        XCTAssertEqual(note.body.count, 3)
    }

    /// Verifies that whenever the Read flag is encoded as a JSON boolean, it gets properly mapped into a Swift Bool.
    ///
    func test_read_flag_encoded_as_boolean_is_properly_mapped_into_swift_booleans() {
        XCTAssertFalse(sampleNotes[0].read)
        XCTAssertTrue(sampleNotes[1].read)
    }

    /// Verifies that whenever the Read flag is encoded as a JSON Integer, it gets properly mapped into a Swift Bool.
    ///
    func test_read_flag_encoded_as_integer_is_properly_mapped_into_swift_booleans() {
        XCTAssertFalse(sampleNotes[2].read)
        XCTAssertTrue(sampleNotes[3].read)
    }

    /// Verifies that Notifications with unknown Types are mapped into the `.unknown` kind.
    ///
    func test_unsupported_note_type_is_parsed_as_unknown_kind() {
        let achievement = sampleNotes.first { $0.type == "like_milestone_achievement" }
        XCTAssertNotNil(achievement)
        XCTAssertEqual(achievement!.kind, .unknown)
    }

    /// Verifies that all of the NoteMedia fields are properly parsed.
    ///
    func test_note_media_is_properly_parsed() {
        let media = sampleNotes[0].body[0].media[0]

        let expectedRange = NSRange(location: 0, length: 3)
        let expectedSize = CGSize(width: 256, height: 256)
        let expectedURL = URL(string: "https://gravatar.tld/some-hash")

        XCTAssertEqual(media.kind, .image)
        XCTAssertEqual(media.type, "image")
        XCTAssertEqual(media.range, expectedRange)
        XCTAssertEqual(media.url, expectedURL)
        XCTAssertEqual(media.size, expectedSize)
    }

    /// Verifies that a NoteMedia with missing size doesn't break parsing (and is treated as an optional).
    ///
    func test_note_media_is_parsed_even_when_optional_fields_are_missing() {
        let media = sampleNotes[0].body[0].media[1]
        XCTAssertNil(media.size)
    }

    /// Verifies that any NoteMedia entry of an unknown `type` is properly mapped into the `.unknown` Kind.
    ///
    func test_note_media_get_unknown_kind_for_unsupported_type_strings() {
        let media = sampleNotes[0].body[0].media[2]
        XCTAssertEqual(media.kind, .unknown)
    }

    /// Verifies that NoteRange of the `.comment` kind is properly parsed.
    ///
    func test_comment_range_is_properly_parsed() {
        let comment = sampleNotes[0].body[0].ranges[0]

        XCTAssertEqual(comment.kind, .comment)
        XCTAssertEqual(comment.siteID, 5555)
        XCTAssertEqual(comment.postID, 4444)
        XCTAssertEqual(comment.commentID, 3333)
    }

    /// Verifies that NoteRange of the `.post` kind is properly parsed.
    ///
    func test_post_range_is_properly_parsed() {
        let post = sampleNotes[0].body[0].ranges[1]

        XCTAssertEqual(post.kind, .post)
        XCTAssertEqual(post.siteID, 123456)
        XCTAssertEqual(post.postID, 654321)
    }

    /// Verifies that NoteRange of the `.site` kind is properly parsed.
    ///
    func test_site_range_is_properly_parsed() {
        let site = sampleNotes[0].body[0].ranges[2]

        XCTAssertEqual(site.kind, .site)
        XCTAssertEqual(site.siteID, 2222)
    }

    /// Verifies that NoteRange of the `.user` kind is properly parsed.
    ///
    func test_user_range_is_properly_parsed() {
        let user = sampleNotes[0].body[0].ranges[3]

        XCTAssertEqual(user.kind, .user)
        XCTAssertEqual(user.userID, 8888)
    }

    /// Verifies that NoteRange of the `.link` kind is properly parsed.
    ///
    func test_link_range_with_non_explicit_type_is_properly_processed() {
        let link = sampleNotes[0].body[0].ranges[4]

        XCTAssertEqual(link.kind, .link)
        XCTAssertEqual(link.url?.absoluteString, "https://somewhere.tld")
    }

    /// Verifies that NoteRange of the `.site` kind is properly parsed (when the type is not explicit).
    ///
    func test_site_range_with_non_explicit_type_is_properly_processed() {
        let site = sampleNotes[0].body[0].ranges[5]

        XCTAssertEqual(site.kind, .site)
        XCTAssertEqual(site.siteID, 88888)
    }

    /// Verifies that NoteBlock of the `.user` kind is properly parsed.
    ///
    func test_user_block_is_properly_parsed() {
        let user = sampleNotes[0].body[0]

        XCTAssertEqual(user.kind, .user)
        XCTAssertEqual(user.text, "Someone AA")
        XCTAssertEqual(user.ranges.count, 6)
        XCTAssertEqual(user.media.count, 3)
        XCTAssertTrue(user.isActionOn(.follow))
        XCTAssertFalse(user.isActionOn(.approve))
        XCTAssertFalse(user.isActionEnabled(.approve))

        XCTAssertEqual(user.meta.identifier(forKey: .user), 111111)
        XCTAssertEqual(user.meta.identifier(forKey: .site), 222222)

        XCTAssertEqual(user.meta.link(forKey: .home), "http://someurl.sometld")
    }

    /// Verifies that NoteBlock of the `.image` kind is properly parsed.
    ///
    func test_image_block_is_properly_parsed() {
        let surgeNote = sampleNotes.first(where: { $0.type == "traffic_surge" })
        XCTAssertEqual(surgeNote?.body[0].kind, .image)
    }

    /// Verifies that NoteBlock of the `.text` kind is properly parsed.
    ///
    func test_text_block_is_properly_parsed() {
        let surgeNote = sampleNotes.first(where: { $0.type == "traffic_surge" })
        XCTAssertEqual(surgeNote?.body[1].kind, .text)
    }

    /// Verifies that NoteBlock of the `.comment` kind is properly parsed.
    ///
    func test_comment_block_is_properly_parsed() {
        let commentNote = sampleNotes.first(where: { $0.kind == .comment })
        XCTAssertEqual(commentNote?.body[1].kind, .comment)
    }

    /// Verifies that the Notification's subtype is properly parsed.
    ///
    func test_store_review_subtype_is_properly_parsed() {
        let storeReview = sampleNotes.first(where: { $0.noteID == 100009 })
        XCTAssertEqual(storeReview?.subtype, "store_review")
        XCTAssertEqual(storeReview?.subkind, .storeReview)
    }

    // MARK: Blaze

    /// Verifies that the Blaze approved notification is properly parsed.
    ///
    func test_blaze_approved_notification_is_properly_parsed() throws {
        let note = try XCTUnwrap(sampleNotes.first(where: { $0.noteID == 8401476681 }))

        XCTAssertEqual(note.hash, 3124)
        XCTAssertEqual(note.read, false)
        XCTAssertEqual(note.icon, "https://gravatar.tld/blaze-icon@3x.png")
        XCTAssertEqual(note.timestamp, "2024-09-04T07:17:18+00:00")
        XCTAssertEqual(note.kind, .blazeApprovedNote)
        XCTAssertEqual(note.url, "https://wordpress.com/advertising/123?blazepress-widget=post-0#get-started")
        XCTAssertEqual(note.title, "Blaze")
        XCTAssertEqual(note.meta.identifier(forKey: .campaignID), 12345)
    }

    /// Verifies that the Blaze rejected notification is properly parsed.
    ///
    func test_blaze_rejected_notification_is_properly_parsed() throws {
        let note = try XCTUnwrap(sampleNotes.first(where: { $0.noteID == 324533 }))

        XCTAssertEqual(note.hash, 1234)
        XCTAssertEqual(note.read, false)
        XCTAssertEqual(note.icon, "https://gravatar.tld/blaze-icon@3x.png")
        XCTAssertEqual(note.timestamp, "2024-09-04T06:47:49+00:00")
        XCTAssertEqual(note.kind, .blazeRejectedNote)
        XCTAssertEqual(note.url, "https://gravatar.tld?blazepress-widget=post-0#get-started")
        XCTAssertEqual(note.title, "Blaze")
        XCTAssertEqual(note.meta.identifier(forKey: .campaignID), 1242324)
    }

    /// Verifies that the Blaze cancelled notification is properly parsed.
    ///
    func test_blaze_cancelled_notification_is_properly_parsed() throws {
        let note = try XCTUnwrap(sampleNotes.first(where: { $0.noteID == 8401493284 }))

        XCTAssertEqual(note.hash, 1919079084)
        XCTAssertEqual(note.read, false)
        XCTAssertEqual(note.icon, "https://s0.wp.com/wp-content/mu-plugins/notes/images/blaze-icon@3x.png")
        XCTAssertEqual(note.timestamp, "2024-09-04T07:27:52+00:00")
        XCTAssertEqual(note.kind, .blazeCancelledNote)
        XCTAssertEqual(note.url, "https://wordpress.com/advertising/campaigns/112182/210109692")
        XCTAssertEqual(note.title, "Blaze")
        XCTAssertEqual(note.meta.identifier(forKey: .campaignID), 112182)
    }

    /// Verifies that the Blaze performed notification is properly parsed.
    ///
    func test_blaze_performed_notification_is_properly_parsed() throws {
        let note = try XCTUnwrap(sampleNotes.first(where: { $0.noteID == 8401476682 }))

        XCTAssertEqual(note.hash, 3124)
        XCTAssertEqual(note.read, false)
        XCTAssertEqual(note.icon, "https://gravatar.tld/blaze-icon@3x.png")
        XCTAssertEqual(note.timestamp, "2024-09-04T07:17:18+00:00")
        XCTAssertEqual(note.kind, .blazePerformedNote)
        XCTAssertEqual(note.url, "https://wordpress.com/advertising/123?blazepress-widget=post-0#get-started")
        XCTAssertEqual(note.title, "Blaze")
        XCTAssertEqual(note.meta.identifier(forKey: .campaignID), 12345)
    }
}


/// Private Methods.
///
private extension NoteListMapperTests {

    /// Returns the NoteListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapNotes(from filename: String) throws -> [Note] {
        let response = Loader.contentsOf(filename)!
        return try NoteListMapper().map(response: response)
    }

    /// Returns the NoteListMapper output upon receiving `notifications` endpoint's response.
    ///
    func mapLoadAllNotificationsResponse() throws -> [Note] {
        return try mapNotes(from: "notifications-load-all")
    }

    /// Returns the NoteListMapper output upon receiving `notifications` endpoint's response.
    ///
    func mapLoadBrokenNotificationsResponse() throws -> [Note] {
        return try mapNotes(from: "broken-notifications")
    }
}
