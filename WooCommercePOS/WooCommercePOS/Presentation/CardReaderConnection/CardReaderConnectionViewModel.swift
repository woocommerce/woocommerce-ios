import SwiftUI

final class CardReaderConnectionViewModel: ObservableObject {
    @Published private(set) var state: CardReaderConnectionUIState

    init(state: CardReaderConnectionUIState) {
        self.state = state
    }

    /// TODO: replace this with card reader connection implementation.
    /// Simulates a successful
    func checkReaderConnection() {
        Task { @MainActor in
            state = .scanningForReader(cancel: { [weak self] in
                self?.state = .notConnected(search: { [weak self] in
                    self?.checkReaderConnection()
                })
            })

            try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))

            state = .readersFound(readerIDs: ["Mock reader 1"],
                                  connect: { [weak self] readerID in
                self?.state = .connectingToReader

                Task { @MainActor in
                    try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
                    self?.state = .connected(readerID: readerID, disconnect: {
                        // TODO: implement reader disconnection action
                        self?.state = .notConnected(search: {
                            self?.checkReaderConnection()
                        })
                    })
                }
            }, continueSearch: { [weak self] in
                self?.state = .scanningForReader(cancel: { [weak self] in
                    self?.state = .notConnected(search: {
                        self?.checkReaderConnection()
                    })
                })
            })
        }
    }
}
