import AppKit

@MainActor
final class DisplayLinkDriver {
    private var timer: Timer?
    private(set) var phase: CGFloat = 0

    let stream: AsyncStream<CGFloat>
    private let continuation: AsyncStream<CGFloat>.Continuation

    init() {
        let pair = AsyncStream<CGFloat>.makeStream()
        stream = pair.stream
        continuation = pair.continuation
    }

    func start(fps: Double = 12) {
        guard timer == nil else { return }

        let interval = 1 / max(fps, 1)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advancePhase()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
        continuation.finish()
    }

    private func advancePhase() {
        phase = (phase + 0.09).truncatingRemainder(dividingBy: 1)
        continuation.yield(phase)
    }
}
