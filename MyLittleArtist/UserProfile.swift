import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int

    init(id: UUID = UUID(), name: String = "", age: Int = 6) {
        self.id = id
        self.name = name
        self.age = age
    }
}
