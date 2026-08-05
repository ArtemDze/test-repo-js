import Foundation

struct FootlightChromeSpec: Decodable, Equatable, Sendable {
    let footlight_navColor: String
    let footlight_buttonColor: String
    let footlight_homeURL: String

    enum CodingKeys: String, CodingKey {
        case footlight_navColor = "nav_color"
        case footlight_buttonColor = "button_color"
        case footlight_homeURL = "home_url"
    }
}

struct FootlightProgrammeSpec: Decodable, Equatable, Sendable {
    let footlight_url: String
    let footlight_bgColor: String
    let footlight_requestNotifications: Bool
    let footlight_actionChangeLink: Bool
    let footlight_navigationBar: FootlightChromeSpec?

    enum CodingKeys: String, CodingKey {
        case footlight_url = "url"
        case footlight_bgColor = "bg_color"
        case footlight_requestNotifications = "request_notifications"
        case footlight_actionChangeLink = "action_change_link"
        case footlight_navigationBar = "navigation_bar"
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        footlight_url = try box.decode(String.self, forKey: .footlight_url)
        footlight_bgColor = try box.decodeIfPresent(String.self, forKey: .footlight_bgColor) ?? "000000"
        footlight_requestNotifications = try box.decodeIfPresent(Bool.self, forKey: .footlight_requestNotifications) ?? false
        footlight_actionChangeLink = try box.decodeIfPresent(Bool.self, forKey: .footlight_actionChangeLink) ?? false
        footlight_navigationBar = try box.decodeIfPresent(FootlightChromeSpec.self, forKey: .footlight_navigationBar)
    }
}
