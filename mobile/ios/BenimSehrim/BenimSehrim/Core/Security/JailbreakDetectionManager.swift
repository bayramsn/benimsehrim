import Foundation
import UIKit

/// Jailbreak detection manager
class JailbreakDetectionManager {
    static let shared = JailbreakDetectionManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if device is jailbroken
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        // Skip jailbreak detection on simulator
        return false
        #else
        return checkSuspiciousFiles() ||
               checkSuspiciousApps() ||
               checkSystemWriteAccess() ||
               checkCydiaURLScheme() ||
               checkFork()
        #endif
    }
    
    // MARK: - Detection Methods
    
    /// Check for suspicious files
    private func checkSuspiciousFiles() -> Bool {
        let suspiciousFiles = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/ssh"
        ]
        
        for path in suspiciousFiles {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    /// Check for suspicious apps
    private func checkSuspiciousApps() -> Bool {
        let suspiciousApps = [
            "cydia://",
            "sileo://",
            "zbra://",
            "filza://"
        ]
        
        for urlScheme in suspiciousApps {
            if let url = URL(string: urlScheme),
               UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if we can write to system directories
    private func checkSystemWriteAccess() -> Bool {
        let testPath = "/private/jailbreak_test.txt"
        let testString = "test"
        
        do {
            try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
    
    /// Check Cydia URL scheme
    private func checkCydiaURLScheme() -> Bool {
        if let url = URL(string: "cydia://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    /// Check fork() availability - disabled in modern iOS
    private func checkFork() -> Bool {
        // fork() is no longer available in iOS, always return false
        return false
    }
}

// MARK: - Root Detection Extension

extension JailbreakDetectionManager {
    /// Comprehensive security check
    func performSecurityCheck() -> SecurityCheckResult {
        let isJailbroken = self.isJailbroken()
        let isDebuggerAttached = self.isDebuggerAttached()
        
        return SecurityCheckResult(
            isJailbroken: isJailbroken,
            isDebuggerAttached: isDebuggerAttached,
            isSafe: !isJailbroken && !isDebuggerAttached
        )
    }
    
    /// Check if debugger is attached
    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        guard result == 0 else {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}

// MARK: - Security Check Result

struct SecurityCheckResult {
    let isJailbroken: Bool
    let isDebuggerAttached: Bool
    let isSafe: Bool
    
    var warningMessage: String? {
        if isJailbroken {
            return "Cihazınız jailbreak edilmiş görünüyor. Güvenlik nedeniyle uygulama kullanılamayabilir."
        }
        if isDebuggerAttached {
            return "Debugger tespit edildi. Lütfen uygulamayı normal şekilde çalıştırın."
        }
        return nil
    }
}
