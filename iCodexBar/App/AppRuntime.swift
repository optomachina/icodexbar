import Foundation

enum AppRuntime {
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment

        return ProcessInfo.processInfo.arguments.contains("--uitesting")
            || environment["XCTestConfigurationFilePath"] != nil
            || environment["XCInjectBundle"] != nil
            || environment["XCInjectBundleInto"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
}
