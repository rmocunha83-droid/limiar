import Foundation
import os

/// Registro de eventos compartilhado entre o app e as extensões via App Group.
/// Guarda um ring buffer pequeno em UserDefaults para diagnóstico em campo
/// (visível na tela "Diagnóstico técnico" das configurações) e espelha tudo
/// no unified logging (Console.app / sysdiagnose).
struct LimiarEventLog {
    struct Entry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let source: String
        let event: String
        let details: [String: String]
    }

    static let maxEntries = 200
    private static let storageKey = "limiarEventLog"
    private static let logger = Logger(subsystem: "com.romeucunha.Limiar", category: "events")

    private let source: String
    private let defaults: UserDefaults

    init(source: String, appGroupIdentifier: String = "group.com.romeucunha.Limiar") {
        self.source = source
        self.defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    func log(_ event: String, _ details: [String: String] = [:]) {
        let detailText = details
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        Self.logger.info("\(self.source, privacy: .public).\(event, privacy: .public) \(detailText, privacy: .public)")

        var entries = Self.loadEntries(from: defaults)
        entries.insert(
            Entry(id: UUID(), timestamp: Date(), source: source, event: event, details: details),
            at: 0
        )
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    static func recentEntries(appGroupIdentifier: String = "group.com.romeucunha.Limiar") -> [Entry] {
        loadEntries(from: UserDefaults(suiteName: appGroupIdentifier) ?? .standard)
    }

    static func clear(appGroupIdentifier: String = "group.com.romeucunha.Limiar") {
        (UserDefaults(suiteName: appGroupIdentifier) ?? .standard).removeObject(forKey: storageKey)
    }

    private static func loadEntries(from defaults: UserDefaults) -> [Entry] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }
}
