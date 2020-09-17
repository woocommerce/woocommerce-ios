import UIKit
import Yosemite

// MARK: - UITableViewConformace conformance
//
extension ProductDownloadListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageAndTitleAndTextTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }

        if let viewModel = viewModel.item(at: indexPath.row) {
            configureCell(cell: cell, model: viewModel.download)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        addEditDownloadableFile(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let item = viewModel.item(at: sourceIndexPath.row) {
            viewModel.remove(at: destinationIndexPath.row)
            viewModel.insert(item, at: destinationIndexPath.row)
        }
    }
}

// MARK: - UITableViewCell Setup
//
extension ProductDownloadListViewController {
    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductDownload) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.name,
                                                                    text: model.fileURL,
                                                                    image: UIImage.menuImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 1)
        cell.updateUI(viewModel: viewModel)
    }
}
