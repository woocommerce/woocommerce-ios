import SwiftUI

enum CardReaderConnectionError: Error {
    case error(Error)
    case incompleteAddress
    case invalidPostalCode
    case criticallyLowBattery
}

enum CardReaderUpdateError: Error {
    case unknown
    case lowBattery
}

enum CardReaderConnectionUIState {
    case notConnected(search: () -> Void)
    case connected(readerID: String, disconnect: () -> Void)

    // MARK: - From card reader connection events

    case scanningForReader(cancel: () -> Void)
    case scanningFailed(error: Error, close: () -> Void)
    case connectingToReader
    case connectingFailed(error: CardReaderConnectionError,
                          retrySearch: () -> Void,
                          cancelSearch: () -> Void)
    case readersFound(readerIDs: [String],
                      connect: (String) -> Void,
                      continueSearch: () -> Void)
    case updateInProgress(requiredUpdate: Bool,
                          progress: Float,
                          cancel: (() -> Void)?)
    case updatingFailed(error: CardReaderUpdateError, tryAgain: (() -> Void)?, close: () -> Void)
}

struct CardReaderConnectionView: View {
    @StateObject var viewModel: CardReaderConnectionViewModel

    init(viewModel: CardReaderConnectionViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
                case .notConnected(let search):
                    ReaderNotConnectedView(searchForReaders: search)
                case .connected(let readerID, let disconnect):
                    ReaderConnectedView(readerID: readerID, disconnect: disconnect)
                case .scanningForReader(let cancel):
                    ScanningForReaderView(cancel: cancel)
                case .scanningFailed(_, _):
                    ScanningForReaderFailedView()
                case .connectingToReader:
                    ConnectingToReaderView()
                case .connectingFailed(_, _, _):
                    ConnectingFailedView()
                case .readersFound(let readerIDs, let connect, let continueSearch):
                    FoundReadersView(readerIDs: readerIDs, connect: connect, continueSearch: continueSearch)
                case .updateInProgress(_, _, _):
                    ReaderUpdateInProgressView()
                case .updatingFailed(_, _, _):
                    ReaderUpdateFailedView()
            }
        }
        .onAppear {
            viewModel.checkReaderConnection()
        }
    }
}

#if DEBUG

extension CardReaderConnectionUIState: CaseIterable, Hashable {
    static var allCases: [CardReaderConnectionUIState] {
        [
            .scanningForReader(cancel: {}),
            .scanningFailed(error: NSError(domain: "", code: 0), close: {}),
            .connectingToReader,
            .connectingFailed(error: .criticallyLowBattery, retrySearch: {}, cancelSearch: {}),
            .readersFound(readerIDs: ["Reader 1", "Reader 2"],
                          connect: { _ in },
                          continueSearch: {}),
            .updateInProgress(requiredUpdate: true,
                              progress: 0.6,
                              cancel: nil),
            .updatingFailed(error: .lowBattery,
                            tryAgain: nil,
                            close: {})
        ]
    }

    static func == (lhs: CardReaderConnectionUIState, rhs: CardReaderConnectionUIState) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
            case .notConnected:
                hasher.combine("notConnected")
            case .connected:
                hasher.combine("connected")
            case .scanningForReader:
                hasher.combine("scanningForReader")
            case .scanningFailed:
                hasher.combine("scanningFailed")
            case .connectingToReader:
                hasher.combine("connectingToReader")
            case .connectingFailed:
                hasher.combine("connectingFailed")
            case .readersFound:
                hasher.combine("readersFound")
            case .updateInProgress:
                hasher.combine("updateInProgress")
            case .updatingFailed:
                hasher.combine("updatingFailed")
        }
    }
}

#Preview {
    @State var selectedState: CardReaderConnectionUIState = .connectingToReader

    return
        VStack {
            Picker(selection: $selectedState, label: EmptyView()) {
                ForEach(CardReaderConnectionUIState.allCases, id: \.self) { state in
                    Text(String(describing: state))
                }
            }
            .pickerStyle(.segmented)
        }
        .sheet(isPresented: .constant(true)) {
            CardReaderConnectionView(viewModel: .init(state: selectedState))
        }
}

#endif
