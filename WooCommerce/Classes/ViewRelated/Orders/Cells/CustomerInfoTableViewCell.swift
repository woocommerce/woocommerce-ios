import UIKit

class CustomerInfoTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.applyHeadlineStyle()
        }
    }
    @IBOutlet private weak var nameLabel: UILabel! {
        didSet {
            nameLabel.applyBodyStyle()
        }
    }
    @IBOutlet private weak var addressLabel: UILabel! {
        didSet {
            addressLabel.applyBodyStyle()
        }
    }


    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }

    var address: String? {
        get {
            return addressLabel.text
        }
        set {
            addressLabel.text = newValue
        }
    }
}
