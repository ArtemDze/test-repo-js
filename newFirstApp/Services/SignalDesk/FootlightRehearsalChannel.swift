import Foundation

struct FootlightRehearsalChannel: FootlightGateChannel {

    func footlight_pullOffer(_ data: [String: Any]) async throws -> FootlightProgrammeSpec {
        _ = try FootlightSealCodec.footlight_seal(try FootlightGateClient.footlight_jsonString(from: data))

        let body: [String: Any] = [
            "url": FootlightCueConfig.footlight_debugTestURL,
            "bg_color": "000000",
            "request_notifications": false,
            "action_change_link": true,
            "navigation_bar": [
                "nav_color": "111111",
                "button_color": "FFFFFF",
                "home_url": FootlightCueConfig.footlight_debugTestURL
            ]
        ]

        let json = try FootlightGateClient.footlight_jsonString(from: body)
        let level = try FootlightSealCodec.footlight_seal(json)
        return try FootlightGateClient.footlight_decodeOffer(fromEncodedLevel: level)
    }

    func footlight_pushEvent(_ data: [String: Any]) async {}
}
