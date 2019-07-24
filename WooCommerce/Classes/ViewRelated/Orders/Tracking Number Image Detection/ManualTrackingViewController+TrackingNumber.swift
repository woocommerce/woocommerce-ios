import UIKit

extension ManualTrackingViewController {
    @objc func trackingNumberImageTapped() {
        promptImage()
    }
}

private extension ManualTrackingViewController {
    func promptImage() {

        let prompt = UIAlertController(title: "Choose a Photo",
                                       message: "Please choose a photo.",
                                       preferredStyle: .actionSheet)

        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            func presentCamera(_ _: UIAlertAction) {
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true)
            }

            let cameraAction = UIAlertAction(title: NSLocalizedString("Camera", comment: ""),
                                             style: .default,
                                             handler: presentCamera)
            prompt.addAction(cameraAction)
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            func presentLibrary(_ _: UIAlertAction) {
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true)
            }

            let libraryAction = UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""),
                                              style: .default,
                                              handler: presentLibrary)
            prompt.addAction(libraryAction)
        }

        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            func presentAlbums(_ _: UIAlertAction) {
                imagePicker.sourceType = .savedPhotosAlbum
                self.present(imagePicker, animated: true)
            }

            let albumsAction = UIAlertAction(title: NSLocalizedString("Saved Albums", comment: ""),
                                             style: .default,
                                             handler: presentAlbums)
            prompt.addAction(albumsAction)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                         style: .cancel,
                                         handler: nil)
        prompt.addAction(cancelAction)

        present(prompt, animated: true, completion: nil)
    }

    func trackingNumberDetected(trackingNumber: String) {
        navigationController?.popToViewController(self, animated: true)
        updateTrackingNumber(trackingNumber: trackingNumber)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ManualTrackingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                                        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Extract chosen image.
        let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage

        // Display image on screen.
        if #available(iOS 13.0, *) {
            let imageDetectionViewController = TrackingNumberImageDetectionViewController(image: originalImage,
                                                                                          onTrackingNumberDetection: trackingNumberDetected)
            dismiss(animated: true, completion: { [weak self] in
                self?.navigationController?.pushViewController(imageDetectionViewController, animated: true)
            })
        } else {
            // Fallback on earlier versions
        }
    }
}
