import Foundation
import Yosemite
import Networking
import Fakes

struct MockCardReaderCapableRemote: CardReaderCapableRemote {
    func loadConnectionToken(for siteID: Int64, completion: @escaping (Result<Networking.ReaderConnectionToken, any Error>) -> Void) {
        // no-op
    }

    var resultForDefaultReaderLocation: (Result<RemoteReaderLocation, any Error>) = .success(RemoteReaderLocation.fake())
    func loadDefaultReaderLocation(for siteID: Int64, onCompletion: @escaping (Result<RemoteReaderLocation, any Error>) -> Void) {
        onCompletion(resultForDefaultReaderLocation)
    }

}
