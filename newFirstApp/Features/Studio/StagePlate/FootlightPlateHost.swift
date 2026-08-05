import SwiftUI
import WebKit

struct FootlightPlateHost: View {
    let footlight_url: String
    let footlight_bgColor: String
    let footlight_spec: FootlightProgrammeSpec?

    var body: some View {
        FootlightPlateBridge(footlight_url: footlight_url, footlight_spec: footlight_spec)
            .ignoresSafeArea()
            .background(Color(footlight_hex: footlight_bgColor))
    }
}

struct FootlightPlateBridge: UIViewControllerRepresentable {
    let footlight_url: String
    let footlight_spec: FootlightProgrammeSpec?

    func makeUIViewController(context: Context) -> FootlightPlateController {
        let host = FootlightPlateController()
        host.footlight_entryURL = footlight_url
        host.footlight_offerSpec = footlight_spec
        return host
    }

    func updateUIViewController(_ host: FootlightPlateController, context: Context) {
        let chromeChanged = host.footlight_offerSpec?.footlight_navigationBar != footlight_spec?.footlight_navigationBar
        host.footlight_offerSpec = footlight_spec
        if chromeChanged {
            host.footlight_refreshChrome()
        }

        guard let next = URL(string: footlight_url) else { return }
        if let prior = URL(string: host.footlight_entryURL), prior == next { return }
        host.footlight_entryURL = footlight_url
        host.footlight_surfaceView.load(URLRequest(url: next))
    }
}
