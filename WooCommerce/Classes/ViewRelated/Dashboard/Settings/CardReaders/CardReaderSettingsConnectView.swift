import UIKit

final class CardReaderSettingsConnectView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var connectButton: UIButton!

    var onPressedConnect: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    private func sharedInit() {
        Bundle.main.loadNibNamed("CardReaderSettingsConnectView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        connectButton.addTarget(self, action: #selector(didPressConnect), for: .touchUpInside)
    }

    @objc func didPressConnect() {
        // TODO. Set up a view model so we can disable the button until state changes
        onPressedConnect?()
    }
}
