import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct SiteTests {

    @Test(arguments: [
        "http://awesomesite.com",
        "http://awesomesite.com/",
        "http://awesomesite.whatever.com",
        "HTTP://awesomesite.com",
        "http://192.168.0.12",
        "https://awesomesite.com"
    ])
    private func forcingHttpsForJetpack(siteAddress: String) {
        let site = Site.defaultMock().copy(url: siteAddress)
        let jetpack = site.toJetpackSite()

        #expect(jetpack.siteAddress.isHttpsScheme)
    }
}

fileprivate extension String {
    var isHttpsScheme: Bool {
        return URL(string: self)?.scheme?.lowercased() == "https"
    }
}
