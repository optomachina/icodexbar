import BackgroundTasks
import Foundation

/// Background refresh service for fetching usage data periodically
/// Uses BGAppRefreshTask for background execution
final class BackgroundRefreshService {
    
    // MARK: - Singleton
    
    static let shared = BackgroundRefreshService()
    
    // MARK: - Constants
    
    let taskIdentifier = "com.icodexbar.refresh"
    
    // MARK: - Properties
    
    private let appGroupID = "group.com.icodexbar.shared"
    private let refreshIntervalKey = "background_refresh_interval"
    
    // MARK: - Refresh Intervals
    
    enum RefreshInterval: Int, CaseIterable, Identifiable {
        case oneMinute = 1
        case twoMinutes = 2
        case fiveMinutes = 5
        case fifteenMinutes = 15
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .oneMinute: return "1 minute"
            case .twoMinutes: return "2 minutes"
            case .fiveMinutes: return "5 minutes"
            case .fifteenMinutes: return "15 minutes"
            }
        }
        
        var timeInterval: TimeInterval {
            TimeInterval(rawValue * 60)
        }
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Register the background task handler
    /// Call this in AppDelegate or App init
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Schedule the next background refresh
    /// Call this when app enters background or after a refresh completes
    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        
        // Get user's preferred interval (default to 5 minutes)
        let interval = savedRefreshInterval
        let earliestBeginDate = Date(timeIntervalSinceNow: interval.timeInterval)
        request.earliestBeginDate = earliestBeginDate
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundRefresh] Scheduled next refresh in \(interval.displayName)")
        } catch {
            print("[BackgroundRefresh] Failed to schedule refresh: \(error)")
        }
    }
    
    /// Cancel any pending background refresh
    func cancelScheduledRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        print("[BackgroundRefresh] Cancelled scheduled refresh")
    }
    
    /// Save user's preferred refresh interval
    func saveRefreshInterval(_ interval: RefreshInterval) {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        defaults.set(interval.rawValue, forKey: refreshIntervalKey)
        defaults.synchronize()
    }
    
    /// Get user's saved refresh interval
    var savedRefreshInterval: RefreshInterval {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        let rawValue = defaults.integer(forKey: refreshIntervalKey)
        return RefreshInterval(rawValue: rawValue) ?? .fiveMinutes
    }
    
    // MARK: - Private Methods
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh before starting work
        scheduleNextRefresh()
        
        // Create a task to fetch usage data
        let fetchTask = Task {
            await UsageStore.shared.fetchAll()
        }
        
        // Set up expiration handler
        // iOS gives ~30 seconds; if we run out of time, we need to clean up
        task.expirationHandler = {
            fetchTask.cancel()
            task.setTaskCompleted(success: false)
            print("[BackgroundRefresh] Task expired before completion")
        }
        
        // Wait for fetch to complete
        Task {
            await fetchTask.value
            if fetchTask.isCancelled {
                task.setTaskCompleted(success: false)
                print("[BackgroundRefresh] Task was cancelled")
            } else {
                task.setTaskCompleted(success: true)
                print("[BackgroundRefresh] Task completed successfully")
            }
        }
    }
}

// MARK: - Convenience Extensions

extension BackgroundRefreshService.RefreshInterval: Comparable {
    static func < (lhs: BackgroundRefreshService.RefreshInterval, rhs: BackgroundRefreshService.RefreshInterval) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
