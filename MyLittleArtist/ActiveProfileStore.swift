//
//  ActiveProfileStore.swift
//  MyLittleArtist
//
//  Created by Achim Sebastian on 04.02.2026.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ActiveProfileStore: ObservableObject {
    @Published var activeProfile: UserProfile?

    @AppStorage("lastSelectedProfileID") private var lastSelectedProfileID: String = ""

    func load(from profiles: [UserProfile]) {
        if let match = profiles.first(where: { $0.id.uuidString == lastSelectedProfileID }) {
            activeProfile = match
        } else {
            activeProfile = profiles.first
            lastSelectedProfileID = activeProfile?.id.uuidString ?? ""
        }
    }

    func select(_ profile: UserProfile) {
        activeProfile = profile
        lastSelectedProfileID = profile.id.uuidString
    }

    var activeProfileID: UUID? { activeProfile?.id }
}
