import Foundation

final class TapToPayEducationStepViewModel {
    let title: String
    let imageName: String
    let descriptionSteps: [String]
    let limit: TapToPayEducationContactlessLimitViewModel?

    init(title: String,
         imageName: String,
         descriptionSteps: [String],
         limit: TapToPayEducationContactlessLimitViewModel? = nil) {
        self.title = title
        self.imageName = imageName
        self.descriptionSteps = descriptionSteps
        self.limit = limit
    }

    init(title: String,
         imageName: String,
         description: String,
         limit: TapToPayEducationContactlessLimitViewModel? = nil) {
        self.title = title
        self.imageName = imageName
        self.descriptionSteps = [description]
        self.limit = limit
    }
}
