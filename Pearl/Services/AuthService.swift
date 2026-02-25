import Foundation
import AuthenticationServices

// MARK: - Authentication Service

class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?
    @Published var isLoading: Bool = false
    
    // MARK: - Sign in with Apple
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = credential.user
                let email = credential.email
                let fullName = credential.fullName
                
                let displayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                // Store user credentials securely
                saveToKeychain(key: "apple_user_id", value: userId)
                if let email = email {
                    saveToKeychain(key: "user_email", value: email)
                }
                if !displayName.isEmpty {
                    saveToKeychain(key: "user_name", value: displayName)
                }
                
                Task { @MainActor in
                    isAuthenticated = true
                }
            }
            
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        deleteFromKeychain(key: "apple_user_id")
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Check Existing Session
    
    func checkExistingSession() {
        if let userId = loadFromKeychain(key: "apple_user_id"), !userId.isEmpty {
            // Verify the Apple ID credential state
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userId) { [weak self] state, _ in
                Task { @MainActor in
                    switch state {
                    case .authorized:
                        self?.isAuthenticated = true
                    case .revoked, .notFound:
                        self?.signOut()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
