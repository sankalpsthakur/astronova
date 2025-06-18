import Foundation

struct AuthenticatedUser: Codable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let fullName: String
    let createdAt: String
    let updatedAt: String
    
    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        } else if let email = email {
            return email
        } else {
            return "User"
        }
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}

struct AppleAuthRequest: Codable {
    let idToken: String
    let userIdentifier: String
    let email: String?
    let firstName: String?
    let lastName: String?
}

struct AuthResponse: Codable {
    let jwtToken: String
    let user: AuthenticatedUser
    let expiresAt: String
}