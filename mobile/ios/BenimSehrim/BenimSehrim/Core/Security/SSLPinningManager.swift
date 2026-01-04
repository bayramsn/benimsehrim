import Foundation
import Security

/// SSL Pinning Manager for secure network communication
class SSLPinningManager {
    static let shared = SSLPinningManager()
    
    // MARK: - Configuration
    
    /// Production API domain
    private let productionDomain = "api.benimsehrim.com"
    
    /// SSL Certificate pins (SHA-256)
    /// Generate with: openssl s_client -connect api.benimsehrim.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
    private let certificatePins: [String] = [
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Primary certificate
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="  // Backup certificate
    ]
    
    // MARK: - Public Methods
    
    /// Validate server trust for SSL pinning
    func validate(serverTrust: SecTrust, domain: String) -> Bool {
        #if DEBUG
        // Skip SSL pinning in debug mode for development
        return true
        #else
        // Only validate production domain
        guard domain == productionDomain else {
            return true
        }
        
        // Get server certificate
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return false
        }
        
        // Get public key
        guard let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
            return false
        }
        
        // Get public key data
        guard let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            return false
        }
        
        // Calculate SHA-256 hash
        let serverKeyHash = sha256(data: serverPublicKeyData)
        let serverKeyHashBase64 = serverKeyHash.base64EncodedString()
        
        // Check if hash matches any of our pins
        return certificatePins.contains(serverKeyHashBase64)
        #endif
    }
    
    // MARK: - Private Methods
    
    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

// MARK: - URLSession Extension

extension URLSession {
    /// Create URLSession with SSL pinning
    static func createSecureSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        let session = URLSession(
            configuration: configuration,
            delegate: SSLPinningDelegate(),
            delegateQueue: nil
        )
        
        return session
    }
}

// MARK: - SSL Pinning Delegate

class SSLPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate SSL pinning
        if SSLPinningManager.shared.validate(serverTrust: serverTrust, domain: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - CommonCrypto Bridge

import CommonCrypto

extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}
