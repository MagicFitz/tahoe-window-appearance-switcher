import Foundation

protocol AppRelaunchServicing {
    func relaunchFinder() throws
}

struct WorkspaceRelaunchService: AppRelaunchServicing {
    func relaunchFinder() throws {
        let result = try ProcessRunner.run("/usr/bin/killall", ["Finder"])
        if !result.succeeded {
            throw AppearanceServiceError.relaunchFailed(result.error)
        }
    }
}
