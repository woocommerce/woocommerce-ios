import Embassy
import XCTest

class mockServer {
    private let loop = try! SelectorEventLoop(selector: try! KqueueSelector())

    private let queue = DispatchQueue(label: "e2e-mock-server")

    public lazy var server = DefaultHTTPServer(eventLoop: loop, app: handleWebRequest)

    public func startWebServer() throws {
        try queue.sync {
            /// Start HTTP server to listen on the port
            try self.server.start()
            debugPrint("Web Server running on port \(self.server.listenAddress.port)")
        }

        queue.async {
            /// Run event loop
            self.loop.runForever()
        }
    }

    public func handleWebRequest(env: [String: Any], startResponse: ((String, [(String, String)]) -> ()), sendBody: ((Data) -> ())) {

            startResponse("404 Not Found", [])
            sendBody(Data())
            return
    }

    public func stopWebServer() {
        self.server.stop()
        self.loop.stop()
    }
}
