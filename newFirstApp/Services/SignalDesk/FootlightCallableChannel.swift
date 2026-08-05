import Foundation

#if canImport(FirebaseFunctions)
import FirebaseFunctions

struct FootlightCallableChannel: FootlightGateChannel {

    private let footlight_endpoint = Functions.functions(region: FootlightCueConfig.footlight_firebaseRegion)

    func footlight_pullOffer(_ data: [String: Any]) async throws -> FootlightProgrammeSpec {
        let sealedRequest = try footlight_encodeAuthKey(data)
        let raw = try await footlight_invoke(sealedRequest)
        let levelBlob = try footlight_extractLevel(from: raw)
        return try FootlightGateClient.footlight_decodeOffer(fromEncodedLevel: levelBlob)
    }

    func footlight_pushEvent(_ data: [String: Any]) async {
        do {
            let sealed = try footlight_encodeAuthKey(data)
            _ = try await footlight_invoke(sealed)
        } catch {
        }
    }

    private func footlight_encodeAuthKey(_ data: [String: Any]) throws -> String {
        let json = try FootlightGateClient.footlight_jsonString(from: data)
        return try FootlightSealCodec.footlight_seal(json)
    }

    private func footlight_invoke(_ sealed: String) async throws -> Any {
        let callable = footlight_endpoint.httpsCallable(FootlightCueConfig.footlight_firebaseFunctionName)
        do {
            let result = try await callable.call(["auth_key": sealed])
#if DEBUG
            print("[Footlight] callable body=\(String(describing: result.data))")
#endif
            return result.data
        } catch {
#if DEBUG
            print("[Footlight] callable error=\(error)")
#endif
            throw error
        }
    }

    private func footlight_extractLevel(from raw: Any) throws -> String {
        guard
            let map = raw as? [String: Any],
            let levelBlob = map["level"] as? String
        else {
            throw FootlightGateError.missingLevel
        }
        return levelBlob
    }
}
#endif
