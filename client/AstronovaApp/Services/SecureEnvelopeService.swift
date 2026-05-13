import CryptoKit
import Foundation

enum SecureEnvelopeError: Error, Equatable {
    case invalidCombinedPayload
    case invalidKeyData
    case unsupportedAlgorithm(String)
    case unsupportedVersion(Int)
}

struct SecureEnvelope: Codable, Equatable {
    let version: Int
    let algorithm: String
    let nonce: String
    let ciphertext: String
    let tag: String

    static let currentVersion = 1
    static let currentAlgorithm = "AES-256-GCM"
}

struct SecureEnvelopeService {
    static let shared = SecureEnvelopeService()

    func makeKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func key(from data: Data) throws -> SymmetricKey {
        guard data.count == 32 else {
            throw SecureEnvelopeError.invalidKeyData
        }

        return SymmetricKey(data: data)
    }

    func encrypt(_ payload: Data, using key: SymmetricKey, associatedData: Data = Data()) throws -> SecureEnvelope {
        let sealedBox = try AES.GCM.seal(payload, using: key, authenticating: associatedData)

        return SecureEnvelope(
            version: SecureEnvelope.currentVersion,
            algorithm: SecureEnvelope.currentAlgorithm,
            nonce: sealedBox.nonce.withUnsafeBytes { Data($0) }.base64EncodedString(),
            ciphertext: sealedBox.ciphertext.base64EncodedString(),
            tag: sealedBox.tag.base64EncodedString()
        )
    }

    func decrypt(_ envelope: SecureEnvelope, using key: SymmetricKey, associatedData: Data = Data()) throws -> Data {
        guard envelope.version == SecureEnvelope.currentVersion else {
            throw SecureEnvelopeError.unsupportedVersion(envelope.version)
        }

        guard envelope.algorithm == SecureEnvelope.currentAlgorithm else {
            throw SecureEnvelopeError.unsupportedAlgorithm(envelope.algorithm)
        }

        guard let nonceData = Data(base64Encoded: envelope.nonce),
              let ciphertext = Data(base64Encoded: envelope.ciphertext),
              let tag = Data(base64Encoded: envelope.tag),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw SecureEnvelopeError.invalidCombinedPayload
        }

        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        return try AES.GCM.open(sealedBox, using: key, authenticating: associatedData)
    }
}
