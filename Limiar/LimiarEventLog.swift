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
        let details = source == "ai" ? Self.safeAIDetails(details) : details
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
        let entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
        return entries.map { entry in
            guard entry.source == "ai" else { return entry }
            return Entry(id: entry.id, timestamp: entry.timestamp, source: entry.source,
                         event: entry.event, details: safeAIDetails(entry.details))
        }
    }

    static func safeAIDetails(_ values: [String: String]) -> [String: String] {
        let numericKeys: Set<String> = ["durationMs", "items", "count", "candidates", "repetitiveItems"]
        let categories: [String: Set<String>] = [
            "outcome": ["remote", "failed", "cancelled"],
            "source": ["remote", "local", "none", "daily-session"],
            "sessionSource": ["remote", "local"],
            "endpoint": ["reading-session", "/api/reading-session", "speech", "/api/speech"]
        ]
        return values.filter { key, value in
            if numericKeys.contains(key) { return Int(value).map { $0 >= 0 } ?? false }
            return categories[key]?.contains(value) == true
        }
    }
}

struct ReadingDeliverySummary {
    let requests: Int
    let failures: Int
    let localSessions: Int
    let p95Milliseconds: Int?

    init(entries: [LimiarEventLog.Entry]) {
        let deliveries = entries.filter { $0.source == "ai" && $0.event == "reading_delivery" }
        requests = deliveries.count
        failures = deliveries.filter { $0.details["outcome"] == "failed" }.count
        localSessions = entries.filter { $0.source == "ai" && $0.event == "ai_local_session_shown" }.count
        let durations = deliveries.compactMap { Int($0.details["durationMs"] ?? "") }.filter { $0 >= 0 }.sorted()
        p95Milliseconds = durations.isEmpty ? nil : durations[max(0, Int(ceil(Double(durations.count) * 0.95)) - 1)]
    }
}
