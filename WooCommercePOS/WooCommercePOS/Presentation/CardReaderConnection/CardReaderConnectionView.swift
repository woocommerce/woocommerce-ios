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
    case scanningForReader(cancel: () -> Void)
    case scanningFailed(error: Error, close: () -> Void)
    case connectingToReader
    case connectingFailed(error: CardReaderConnectionError,
                          retrySearch: () -> Void,
                          cancelSearch: () -> Void)
    case readersFound(readerIDs: [String],
                      connect: (String) -> Void,
                      continueSearch: () -> Void,
                      cancelSearch: () -> Void)
    case updateInProgress(requiredUpdate: Bool,
                          progress: Float,
                          cancel: (() -> Void)?)
    case updatingFailed(error: CardReaderUpdateError, tryAgain: (() -> Void)?, close: () -> Void)
}

final class CardReaderConnectionViewModel: ObservableObject {
    @Published private(set) var state: CardReaderConnectionUIState

    init(state: CardReaderConnectionUIState) {
        self.state = state
    }
}

struct CardReaderConnectionView: View {
    @StateObject var viewModel: CardReaderConnectionViewModel

    init(viewModel: CardReaderConnectionViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        switch viewModel.state {
            case .scanningForReader(let cancel):
                ScanningForReaderView()
            case .scanningFailed(let error, let close):
                ScanningForReaderFailedView()
            case .connectingToReader:
                ConnectingToReaderView()
            case .connectingFailed(let error, let retrySearch, let cancelSearch):
                ConnectingFailedView()
            case .readersFound(let readerIDs, let connect, let continueSearch, let cancelSearch):
                FoundReadersView(readerIDs: readerIDs)
            case .updateInProgress(let requiredUpdate, let progress, let cancel):
                ReaderUpdateInProgressView()
            case .updatingFailed(let error, let tryAgain, let close):
                ReaderUpdateFailedView()
        }
    }
}

#if DEBUG

extension CardReaderConnectionUIState: CaseIterable, Hashable {
    static var allCases: [CardReaderConnectionUIState] {
        [
            .scanningForReader(cancel: {}),
            .scanningFailed(error: NSError(domain: "", code: 0), close: {})
        ]
    }

    static func == (lhs: CardReaderConnectionUIState, rhs: CardReaderConnectionUIState) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
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
