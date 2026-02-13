import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var avatarEmoji: String?

    init(id: UUID = UUID(), name: String = "", age: Int = 6, avatarEmoji: String? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarEmoji = avatarEmoji
    }
}
