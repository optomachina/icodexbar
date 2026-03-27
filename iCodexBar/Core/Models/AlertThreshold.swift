import Foundation

struct AlertThreshold: Codable, Identifiable, Equatable {
    let id: UUID
    let provider: Provider
    var thresholdPercent: Int
    var isEnabled: Bool

    init(provider: Provider, thresholdPercent: Int = 80, isEnabled: Bool = true) {
        self.id = UUID()
        self.provider = provider
        self.thresholdPercent = thresholdPercent
        self.isEnabled = isEnabled
    }
}

struct AlertThresholdStore: Codable {
    var thresholds: [AlertThreshold]

    init(thresholds: [AlertThreshold] = Provider.allCases.map { AlertThreshold(provider: $0) }) {
        self.thresholds = thresholds
    }

    mutating func update(_ threshold: AlertThreshold) {
        if let idx = thresholds.firstIndex(where: { $0.provider == threshold.provider }) {
            thresholds[idx] = threshold
        } else {
            thresholds.append(threshold)
        }
    }

    func threshold(for provider: Provider) -> AlertThreshold? {
        thresholds.first { $0.provider == provider }
    }

    mutating func setEnabled(_ enabled: Bool, for provider: Provider) {
        if let idx = thresholds.firstIndex(where: { $0.provider == provider }) {
            thresholds[idx].isEnabled = enabled
        }
    }

    mutating func setThresholdPercent(_ percent: Int, for provider: Provider) {
        if let idx = thresholds.firstIndex(where: { $0.provider == provider }) {
            thresholds[idx].thresholdPercent = max(1, min(100, percent))
        }
    }
}
