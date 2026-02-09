import Testing
import Foundation
@testable import WordPressUI

struct `Gravatar Tests` {
    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `unknown gravatar URL matches URL with subdomain and query parameters`() {
        let url = URL(string: "https://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536?s=256&r=G")!
        let gravatar = Gravatar(url)
        #expect(gravatar == nil)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `unknown gravatar URL matches URL without subdomains`() {
        let url = URL(string: "https://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536")!
        let gravatar = Gravatar(url)
        #expect(gravatar == nil)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `unknown gravatar URL matches URL with HTTP schema`() {
        let url = URL(string: "http://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536")!
        let gravatar = Gravatar(url)
        #expect(gravatar == nil)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `gravatar rejects incorrect path`() {
        let url = URL(string: "http://0.gravatar.com/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        #expect(gravatar == nil)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `gravatar rejects incorrect host`() {
        let url = URL(string: "http://0.argvatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        #expect(gravatar == nil)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `gravatar removes query parameters`() {
        let url = URL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a?d=http://0.gravatar.com/5b415e3c9c245e557af9f580eeb8760a")!
        let expected = URL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        #expect(gravatar != nil)
        #expect(gravatar!.canonicalURL == expected)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `gravatar forces HTTPS`() {
        let url = URL(string: "http://0.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let expected = URL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let gravatar = Gravatar(url)
        #expect(gravatar != nil)
        #expect(gravatar!.canonicalURL == expected)
    }

    @available(*, deprecated, message: "Deprecated because of Gravatar usage")
    @Test func `gravatar appends size query`() {
        let url = URL(string: "http://0.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a")!
        let expected = URL(string: "https://secure.gravatar.com/avatar/5b415e3c9c245e557af9f580eeb8760a?s=128&d=404")!
        let gravatar = Gravatar(url)
        #expect(gravatar != nil)
        #expect(gravatar!.urlWithSize(128) == expected)
    }
}
