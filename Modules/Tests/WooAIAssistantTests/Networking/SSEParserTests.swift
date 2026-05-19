import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct SSEParserTests {

    @Test
    func test_feed_when_single_complete_event_then_returns_one_event() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed("data: hello\n\n")

        // Then
        #expect(events == [SSEParser.Event(data: "hello")])
    }

    @Test
    func test_feed_when_split_across_chunks_then_buffers_and_emits_on_terminator() {
        // Given
        var parser = SSEParser()

        // When
        let firstChunk = parser.feed("data: hel")
        let secondChunk = parser.feed("lo\n\n")

        // Then
        #expect(firstChunk.isEmpty)
        #expect(secondChunk == [SSEParser.Event(data: "hello")])
    }

    @Test
    func test_feed_when_multiple_data_lines_in_one_event_then_joined_with_newline() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed("data: line1\ndata: line2\n\n")

        // Then
        #expect(events == [SSEParser.Event(data: "line1\nline2")])
    }

    @Test
    func test_feed_when_comment_lines_then_ignored() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed(": this is a heartbeat\ndata: real\n\n")

        // Then
        #expect(events == [SSEParser.Event(data: "real")])
    }

    @Test
    func test_feed_when_unknown_fields_then_ignored() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed("event: ping\nid: 7\nretry: 5000\ndata: payload\n\n")

        // Then
        #expect(events == [SSEParser.Event(data: "payload")])
    }

    @Test
    func test_feed_when_done_sentinel_then_emitted_as_regular_event() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed("data: [DONE]\n\n")

        // Then
        #expect(events == [SSEParser.Event(data: "[DONE]")])
    }

    @Test
    func test_feed_when_crlf_line_breaks_then_parsed_correctly() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed("data: line1\r\ndata: line2\r\n\r\n")

        // Then
        #expect(events == [SSEParser.Event(data: "line1\nline2")])
    }

    @Test
    func test_feed_when_bare_cr_line_breaks_then_parsed_correctly() {
        // Given
        var parser = SSEParser()

        // When
        let live = parser.feed("data: line1\rdata: line2\r\r")
        let drained = parser.finish()

        // Then
        #expect(live.isEmpty)
        #expect(drained == [SSEParser.Event(data: "line1\nline2")])
    }

    @Test
    func test_finish_when_event_lacks_trailing_blank_line_then_drained() {
        // Given
        var parser = SSEParser()

        // When
        let live = parser.feed("data: trailing\n")
        let drained = parser.finish()

        // Then
        #expect(live.isEmpty)
        #expect(drained == [SSEParser.Event(data: "trailing")])
    }

    @Test
    func test_feed_when_no_space_after_colon_then_value_kept_intact() {
        // Given
        var parser = SSEParser()

        // When
        let events = parser.feed("data:no-space\n\n")

        // Then
        #expect(events == [SSEParser.Event(data: "no-space")])
    }

    @Test
    func test_feed_when_crlf_split_across_chunks_then_treated_as_single_terminator() {
        // Given
        var parser = SSEParser()

        // When
        let firstChunk = parser.feed("data: hello\r")
        let secondChunk = parser.feed("\ndata: world\r\n\r\n")

        // Then
        #expect(firstChunk.isEmpty)
        #expect(secondChunk == [SSEParser.Event(data: "hello\nworld")])
    }
}
