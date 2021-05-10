import UIKit

 class PluginTableViewCell: UITableViewCell {

     @IBOutlet private var nameLabel: UILabel!
     @IBOutlet private var descriptionLabel: UILabel!

     override func awakeFromNib() {
         super.awakeFromNib()
         applyDefaultBackgroundStyle()

         nameLabel.applyBodyStyle()
         nameLabel.numberOfLines = 2

         descriptionLabel.applySecondaryBodyStyle()
         descriptionLabel.numberOfLines = 2
     }

     func update(viewModel: PluginListCellViewModel) {
         nameLabel.text = viewModel.name
         descriptionLabel.text = viewModel.description
     }
 }
