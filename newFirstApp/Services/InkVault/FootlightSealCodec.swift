import Foundation

enum FootlightSealCodecError: Error {
    case encodeFailed
}

enum FootlightSealCodec {

    private static let footlight_noisePool = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") as [Character]

    static func footlight_seal(_ plain: String) throws -> String {
        let base64 = Data(plain.utf8).base64EncodedString()
        var sealed = String()
        sealed.reserveCapacity(base64.count * 2)

        var index = base64.startIndex
        while index < base64.endIndex {
            guard let noise = footlight_noisePool.randomElement() else {
                throw FootlightSealCodecError.encodeFailed
            }
            sealed.append(noise)
            sealed.append(base64[index])
            index = base64.index(after: index)
        }
        return sealed
    }

    static func footlight_open(_ sealed: String) -> String? {
        guard sealed.count % 2 == 0 else { return nil }

        var base64 = String()
        base64.reserveCapacity(sealed.count / 2)

        let chars = Array(sealed)
        var i = 1
        while i < chars.count {
            base64.append(chars[i])
            i += 2
        }

        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
