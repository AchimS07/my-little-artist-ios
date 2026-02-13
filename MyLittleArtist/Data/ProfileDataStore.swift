//
//  ProfileDataStore.swift
//  MyLittleArtist
//
//  Created by Achim Sebastian on 04.02.2026.
//

import Foundation

enum ProfileDataStore {
    // Base: Documents/Profiles/<uuid>/
    static func profileDir(profileID: UUID) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Profiles", isDirectory: true)
            .appendingPathComponent(profileID.uuidString, isDirectory: true)

        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(profileID: UUID, filename: String) throws -> URL {
        try profileDir(profileID: profileID).appendingPathComponent(filename, isDirectory: false)
    }

    // Generic JSON read/write
    static func saveJSON<T: Encodable>(_ value: T, profileID: UUID, filename: String) throws {
        let url = try url(profileID: profileID, filename: filename)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: [.atomic])
    }

    static func loadJSON<T: Decodable>(_ type: T.Type, profileID: UUID, filename: String) throws -> T? {
        let url = try url(profileID: profileID, filename: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}
