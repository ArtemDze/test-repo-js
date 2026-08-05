import UIKit
import WebKit

final class FootlightSheetController: UIViewController {
    let footlight_embeddedView: WKWebView
    var footlight_onClosed: (() -> Void)?

    init(embeddedView: WKWebView) {
        self.footlight_embeddedView = embeddedView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        var closeConfig = UIButton.Configuration.plain()
        closeConfig.title = "Done"
        closeConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .semibold)
            return outgoing
        }
        let close = UIButton(configuration: closeConfig)
        close.addTarget(self, action: #selector(footlight_closePressed), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false

        footlight_embeddedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footlight_embeddedView)
        view.addSubview(close)

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            close.heightAnchor.constraint(equalToConstant: 40),

            footlight_embeddedView.topAnchor.constraint(equalTo: close.bottomAnchor, constant: 2),
            footlight_embeddedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footlight_embeddedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footlight_embeddedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || parent == nil {
            footlight_onClosed?()
        }
    }

    @objc private func footlight_closePressed() {
        dismiss(animated: true)
    }
}
