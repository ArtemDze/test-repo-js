import UIKit

final class FootlightFaultBanner: UIView {
    var footlight_onRetry: (() -> Void)?

    private let footlight_iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        iv.tintColor = UIColor(red: 0.72, green: 0.58, blue: 0.36, alpha: 0.9)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let footlight_detailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.70, green: 0.68, blue: 0.65, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let footlight_retryControl: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = UIColor(red: 0.72, green: 0.58, blue: 0.36, alpha: 1)
        config.baseForegroundColor = UIColor(red: 0.05, green: 0.055, blue: 0.07, alpha: 1)
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.05, green: 0.055, blue: 0.07, alpha: 0.96)

        let column = UIStackView(arrangedSubviews: [footlight_iconView, footlight_detailLabel, footlight_retryControl])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 14
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        NSLayoutConstraint.activate([
            footlight_iconView.widthAnchor.constraint(equalToConstant: 36),
            footlight_iconView.heightAnchor.constraint(equalToConstant: 36),
            column.centerYAnchor.constraint(equalTo: centerYAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
        ])
        footlight_retryControl.addTarget(self, action: #selector(footlight_retryPressed), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func footlight_present(text: String) {
        footlight_detailLabel.text = text
        isHidden = false
        superview?.bringSubviewToFront(self)
    }

    func footlight_dismiss() {
        isHidden = true
    }

    @objc private func footlight_retryPressed() { footlight_onRetry?() }
}
