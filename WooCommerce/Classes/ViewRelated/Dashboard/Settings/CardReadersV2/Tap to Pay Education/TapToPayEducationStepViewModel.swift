import Foundation

final class TapToPayEducationStepViewModel {
    let title: String
    let imageName: String
    let descriptionSteps: [String]
    let limit: AboutTapToPayContactlessLimitViewModel?

    init(title: String,
         imageName: String,
         descriptionSteps: [String],
         limit: AboutTapToPayContactlessLimitViewModel? = nil) {
        self.title = title
        self.imageName = imageName
        self.descriptionSteps = descriptionSteps
        self.limit = limit
    }

    init(title: String,
         imageName: String,
         description: String,
         limit: AboutTapToPayContactlessLimitViewModel? = nil) {
        self.title = title
        self.imageName = imageName
        self.descriptionSteps = [description]
        self.limit = limit
    }
}
