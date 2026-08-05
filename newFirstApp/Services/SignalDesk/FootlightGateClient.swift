import Foundation

enum FootlightGateError: Error {
    case serializeFailed
    case missingLevel
    case parseFailed(underlying: Error)
}

protocol FootlightGateChannel: Sendable {
    func footlight_pullOffer(_ data: [String: Any]) async throws -> FootlightProgrammeSpec
    func footlight_pushEvent(_ data: [String: Any]) async
}

enum FootlightGateClient {

    static var footlight_channel: any FootlightGateChannel = {
#if canImport(FirebaseFunctions)
        FootlightCallableChannel()
#else
        FootlightRehearsalChannel()
#endif
    }()

    static func footlight_pullOffer(_ data: [String: Any]) async throws -> FootlightProgrammeSpec {
#if DEBUG
        print("[Footlight] pullOffer payload=\(data)")
#endif
        return try await footlight_channel.footlight_pullOffer(data)
    }

    static func footlight_pushEvent(_ data: [String: Any]) {
        Task.detached {
            await footlight_channel.footlight_pushEvent(data)
        }
    }

    static func footlight_jsonString(from object: Any) throws -> String {
        let bytes = try JSONSerialization.data(withJSONObject: object)
        guard let text = String(data: bytes, encoding: .utf8) else {
            throw FootlightGateError.serializeFailed
        }
        return text
    }

    static func footlight_decodeOffer(fromEncodedLevel sealed: String) throws -> FootlightProgrammeSpec {
        guard let plain = FootlightSealCodec.footlight_open(sealed) else {
            throw FootlightGateError.missingLevel
        }
#if DEBUG
        print("[Footlight] opened level json=\(plain)")
#endif
        do {
            return try JSONDecoder().decode(FootlightProgrammeSpec.self, from: Data(plain.utf8))
        } catch {
            throw FootlightGateError.parseFailed(underlying: error)
        }
    }
}
