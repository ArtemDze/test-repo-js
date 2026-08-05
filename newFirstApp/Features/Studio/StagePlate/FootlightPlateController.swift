import UIKit
import WebKit

final class FootlightPlateController: UIViewController {
    var footlight_entryURL: String = ""
    var footlight_offerSpec: FootlightProgrammeSpec?
    private(set) var footlight_surfaceView: WKWebView!

    private var footlight_sheetRegistry: [ObjectIdentifier: FootlightSheetController] = [:]
    private var footlight_lastEmittedURL: URL?
    private var footlight_statusBarTone: UIStatusBarStyle = .lightContent

    private var footlight_progressWatch: NSKeyValueObservation?
    private var footlight_backWatch: NSKeyValueObservation?
    private var footlight_forwardWatch: NSKeyValueObservation?
    private var footlight_urlWatch: NSKeyValueObservation?

    private let footlight_loadMeter: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.isHidden = true
        return bar
    }()

    private lazy var footlight_faultBanner: FootlightFaultBanner = {
        let banner = FootlightFaultBanner()
        banner.footlight_onRetry = { [weak self] in self?.footlight_retryEntryLoad() }
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.isHidden = true
        return banner
    }()

    private let footlight_statusStrip = UIView()
    private let footlight_chromeTray = UIView()
    private let footlight_rewindButton = UIButton(type: .system)
    private let footlight_nestButton = UIButton(type: .system)
    private let footlight_advanceButton = UIButton(type: .system)

    override var preferredStatusBarStyle: UIStatusBarStyle { footlight_statusBarTone }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        footlight_bootstrapSurfaceInstance()
        footlight_assembleChrome()
        footlight_assembleSurfaceLayout()
        footlight_bindSurfaceObservers()
        footlight_refreshChrome()
        footlight_syncNavEnabled()
        footlight_openEntryURL()
    }

    deinit {
        [footlight_progressWatch, footlight_backWatch, footlight_forwardWatch, footlight_urlWatch].forEach { $0?.invalidate() }
        footlight_sheetRegistry.values.forEach { $0.dismiss(animated: false) }
        footlight_sheetRegistry.removeAll()
    }

    private func footlight_bootstrapSurfaceInstance() {
        if let standby = FootlightPlateRuntime.footlight_consumeStandby() {
            footlight_surfaceView = standby
        } else {
            footlight_surfaceView = WKWebView(frame: .zero, configuration: FootlightPlateRuntime.footlight_buildConfiguration())
        }
        footlight_applySurfaceDefaults(to: footlight_surfaceView)
    }

    private func footlight_assembleChrome() {
        footlight_statusStrip.translatesAutoresizingMaskIntoConstraints = false
        footlight_chromeTray.translatesAutoresizingMaskIntoConstraints = false

        footlight_rewindButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        footlight_nestButton.setImage(UIImage(systemName: "house"), for: .normal)
        footlight_advanceButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        [footlight_rewindButton, footlight_nestButton, footlight_advanceButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(footlight_statusStrip)
        view.addSubview(footlight_chromeTray)
        footlight_chromeTray.addSubview(footlight_rewindButton)
        footlight_chromeTray.addSubview(footlight_nestButton)
        footlight_chromeTray.addSubview(footlight_advanceButton)

        footlight_rewindButton.addTarget(self, action: #selector(footlight_rewindTapped), for: .touchUpInside)
        footlight_nestButton.addTarget(self, action: #selector(footlight_nestTapped), for: .touchUpInside)
        footlight_advanceButton.addTarget(self, action: #selector(footlight_advanceTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            footlight_statusStrip.topAnchor.constraint(equalTo: view.topAnchor),
            footlight_statusStrip.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footlight_statusStrip.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footlight_statusStrip.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            footlight_chromeTray.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footlight_chromeTray.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footlight_chromeTray.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footlight_chromeTray.heightAnchor.constraint(equalToConstant: 60),

            footlight_rewindButton.leadingAnchor.constraint(equalTo: footlight_chromeTray.leadingAnchor),
            footlight_rewindButton.centerYAnchor.constraint(equalTo: footlight_chromeTray.centerYAnchor),
            footlight_rewindButton.widthAnchor.constraint(equalToConstant: 60),
            footlight_rewindButton.heightAnchor.constraint(equalToConstant: 60),

            footlight_nestButton.centerXAnchor.constraint(equalTo: footlight_chromeTray.centerXAnchor),
            footlight_nestButton.centerYAnchor.constraint(equalTo: footlight_chromeTray.centerYAnchor),
            footlight_nestButton.widthAnchor.constraint(equalToConstant: 60),
            footlight_nestButton.heightAnchor.constraint(equalToConstant: 60),

            footlight_advanceButton.trailingAnchor.constraint(equalTo: footlight_chromeTray.trailingAnchor, constant: -10),
            footlight_advanceButton.centerYAnchor.constraint(equalTo: footlight_chromeTray.centerYAnchor),
            footlight_advanceButton.widthAnchor.constraint(equalToConstant: 60),
            footlight_advanceButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func footlight_assembleSurfaceLayout() {
        footlight_surfaceView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footlight_surfaceView)

        let pull = UIRefreshControl()
        pull.addTarget(self, action: #selector(footlight_pullReloaded), for: .valueChanged)
        footlight_surfaceView.scrollView.refreshControl = pull

        view.addSubview(footlight_loadMeter)
        view.addSubview(footlight_faultBanner)

        NSLayoutConstraint.activate([
            footlight_surfaceView.topAnchor.constraint(equalTo: footlight_statusStrip.bottomAnchor),
            footlight_surfaceView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footlight_surfaceView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footlight_surfaceView.bottomAnchor.constraint(equalTo: footlight_chromeTray.topAnchor),

            footlight_loadMeter.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            footlight_loadMeter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footlight_loadMeter.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            footlight_faultBanner.topAnchor.constraint(equalTo: footlight_statusStrip.bottomAnchor),
            footlight_faultBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footlight_faultBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footlight_faultBanner.bottomAnchor.constraint(equalTo: footlight_chromeTray.topAnchor),
        ])
    }

    private func footlight_bindSurfaceObservers() {
        footlight_progressWatch = footlight_surfaceView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
            self?.footlight_paintProgress(view.estimatedProgress)
        }
        footlight_backWatch = footlight_surfaceView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
            self?.footlight_syncNavEnabled()
        }
        footlight_forwardWatch = footlight_surfaceView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
            self?.footlight_syncNavEnabled()
        }
        footlight_urlWatch = footlight_surfaceView.observe(\.url, options: [.new]) { [weak self] _, change in
            guard let next = change.newValue ?? nil else { return }
            self?.footlight_emitLinkChange(next)
        }
    }

    private func footlight_applySurfaceDefaults(to view: WKWebView) {
        view.uiDelegate = self
        view.navigationDelegate = self
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.keyboardDismissMode = .interactive
        view.scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    func footlight_refreshChrome() {
        let palette = footlight_chromePalette()
        footlight_statusStrip.backgroundColor = palette.bg
        footlight_chromeTray.backgroundColor = palette.bg
        footlight_rewindButton.tintColor = palette.tint
        footlight_nestButton.tintColor = palette.tint
        footlight_advanceButton.tintColor = palette.tint

        footlight_statusBarTone = palette.bg.footlight_isLight ? .darkContent : .lightContent
        setNeedsStatusBarAppearanceUpdate()

        let homeURL = footlight_offerSpec?.footlight_navigationBar?.footlight_homeURL ?? ""
        footlight_nestButton.isHidden = homeURL.isEmpty
    }

    private func footlight_chromePalette() -> (bg: UIColor, tint: UIColor) {
        guard let chrome = footlight_offerSpec?.footlight_navigationBar else {
            return (.black, .white)
        }
        return (
            UIColor(footlight_hex: chrome.footlight_navColor) ?? .black,
            UIColor(footlight_hex: chrome.footlight_buttonColor) ?? .white
        )
    }

    private func footlight_syncNavEnabled() {
        footlight_rewindButton.isEnabled = footlight_surfaceView?.canGoBack ?? false
        footlight_advanceButton.isEnabled = footlight_surfaceView?.canGoForward ?? false
    }

    @objc private func footlight_rewindTapped() {
        if footlight_surfaceView.canGoBack { footlight_surfaceView.goBack() }
    }

    @objc private func footlight_advanceTapped() {
        if footlight_surfaceView.canGoForward { footlight_surfaceView.goForward() }
    }

    @objc private func footlight_nestTapped() {
        let target = footlight_offerSpec?.footlight_navigationBar?.footlight_homeURL ?? footlight_entryURL
        guard let url = URL(string: target) else { return }
        footlight_surfaceView.load(URLRequest(url: url))
    }

    @objc private func footlight_pullReloaded() {
        footlight_surfaceView.reloadFromOrigin()
    }

    private func footlight_emitLinkChange(_ url: URL) {
        guard footlight_offerSpec?.footlight_actionChangeLink == true, url != footlight_lastEmittedURL else { return }
        footlight_lastEmittedURL = url
        FootlightGateClient.footlight_pushEvent([
            "external_id": FootlightCueConfig.footlight_externalID(),
            "app_id": FootlightCueConfig.footlight_appID,
            "action": "change_link",
            "link": url.absoluteString
        ])
    }

    private func footlight_retryEntryLoad() {
        footlight_faultBanner.footlight_dismiss()
        footlight_openEntryURL()
    }

    private func footlight_openEntryURL() {
        guard let destination = URL(string: footlight_entryURL) else {
            footlight_faultBanner.footlight_present(text: "Invalid URL")
            return
        }
        if footlight_surfaceView.url == destination { return }
        if footlight_surfaceView.isLoading, footlight_surfaceView.url?.absoluteString == destination.absoluteString { return }
        footlight_surfaceView.load(URLRequest(url: destination))
    }

    private func footlight_paintProgress(_ value: Double) {
        footlight_loadMeter.isHidden = value >= 1.0 || value <= 0.0
        footlight_loadMeter.setProgress(Float(value), animated: true)
    }

    private func footlight_absorbLoadFailure(_ error: Error) {
        footlight_surfaceView.scrollView.refreshControl?.endRefreshing()
        let ns = error as NSError
        if ns.code == NSURLErrorCancelled { return }
        footlight_faultBanner.footlight_present(text: ns.localizedDescription)
    }

    private func footlight_presentOnTop(_ controller: UIViewController) {
        FootlightPresentHub.footlight_present(controller, anchor: self, webView: footlight_surfaceView)
    }
}

extension FootlightPlateController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        footlight_faultBanner.footlight_dismiss()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        footlight_absorbLoadFailure(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        footlight_absorbLoadFailure(error)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let mainFrame = navigationAction.targetFrame?.isMainFrame ?? true
        switch FootlightPlatePolicy.footlight_verdict(for: navigationAction.request.url, isMainFrame: mainFrame) {
        case .allowInWebView:
            decisionHandler(.allow)
        case .reject:
            decisionHandler(.cancel)
        case .openExternally(let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }
}

extension FootlightPlateController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard FootlightPlatePolicy.footlight_shouldSpawnSheet(targetFrame: navigationAction.targetFrame) else {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        let child = WKWebView(frame: .zero, configuration: configuration)
        footlight_applySurfaceDefaults(to: child)

        let sheet = FootlightSheetController(embeddedView: child)
        sheet.modalPresentationStyle = .pageSheet
        sheet.footlight_onClosed = { [weak self, weak child] in
            guard let child else { return }
            self?.footlight_sheetRegistry[ObjectIdentifier(child)] = nil
        }
        footlight_sheetRegistry[ObjectIdentifier(child)] = sheet
        footlight_presentOnTop(sheet)
        return child
    }

    func webViewDidClose(_ webView: WKWebView) {
        let key = ObjectIdentifier(webView)
        guard let sheet = footlight_sheetRegistry.removeValue(forKey: key) else { return }
        if sheet.presentingViewController != nil {
            sheet.dismiss(animated: true)
        }
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        footlight_presentOnTop(alert)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        footlight_presentOnTop(alert)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text)
        })
        footlight_presentOnTop(alert)
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}
