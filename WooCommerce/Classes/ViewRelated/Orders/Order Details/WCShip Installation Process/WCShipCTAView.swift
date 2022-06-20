import SwiftUI

final class WCShipCTAHostingController: UIHostingController<WCShipCTAView> {

    init() {
        super.init(rootView: WCShipCTAView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


struct WCShipCTAView: View {
    var body: some View {
        Text("Hello WCShip world!")
    }
}

struct WCShipCTAView_Previews: PreviewProvider {
    static var previews: some View {
        WCShipCTAView()
    }
}
