import Foundation

/// Stored metadata about a configured API key.
/// The actual key value lives in the Keychain — never in this struct.
struct APIKeyRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let provider: Provider
    var label: String?
    let createdAt: Date

    init(provider: Provider, label: String? = nil) {
        self.id = UUID()
        self.provider = provider
        self.label = label
        self.createdAt = Date()
    }
}

struct APIKeyRecordStore: Codable {
    var records: [APIKeyRecord]

    init(records: [APIKeyRecord] = []) {
        self.records = records
    }

    mutating func add(_ record: APIKeyRecord) {
        records.removeAll { $0.provider == record.provider }
        records.append(record)
    }

    mutating func remove(provider: Provider) {
        records.removeAll { $0.provider == provider }
    }

    func record(for provider: Provider) -> APIKeyRecord? {
        records.first { $0.provider == provider }
    }

    func hasKey(for provider: Provider) -> Bool {
        record(for: provider) != nil
    }
}
