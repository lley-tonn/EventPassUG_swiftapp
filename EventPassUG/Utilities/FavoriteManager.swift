//
//  FavoriteManager.swift
//  EventPassUG
//
//  Manages favorite events using AppStorage
//

import Foundation
import SwiftUI

@MainActor
class FavoriteManager: ObservableObject {
    @AppStorage("favoriteEventIds") private var favoriteIdsData: Data = Data()

    @Published var favoriteEventIds: Set<UUID> = []

    static let shared = FavoriteManager()

    init() {
        loadFavorites()
    }

    func loadFavorites() {
        if let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: favoriteIdsData) {
            favoriteEventIds = decoded
        }
    }

    func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteEventIds) {
            favoriteIdsData = encoded
        }
    }

    func toggleFavorite(eventId: UUID) {
        if favoriteEventIds.contains(eventId) {
            favoriteEventIds.remove(eventId)
        } else {
            favoriteEventIds.insert(eventId)
        }
        saveFavorites()
    }

    func isFavorite(eventId: UUID) -> Bool {
        favoriteEventIds.contains(eventId)
    }

    func addFavorite(eventId: UUID) {
        favoriteEventIds.insert(eventId)
        saveFavorites()
    }

    func removeFavorite(eventId: UUID) {
        favoriteEventIds.remove(eventId)
        saveFavorites()
    }

    func clearAll() {
        favoriteEventIds.removeAll()
        saveFavorites()
    }
}
