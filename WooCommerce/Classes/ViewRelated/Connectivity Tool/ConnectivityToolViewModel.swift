import Foundation

final class ConnectivityToolViewModel {

    @Published var cards: [ConnectivityTool.Card] = [.init(title: "Internet Connection",
                                                           icon: .system("wifi"),
                                                           state: .inProgress)]

    init() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.cards = [
                .init(title: "Internet Connection",
                      icon: .system("wifi"),
                      state: .success),
                .init(title: "WordPress.com servers",
                      icon: .system("server.rack"),
                      state: .inProgress)
            ]
        }
    }

}
