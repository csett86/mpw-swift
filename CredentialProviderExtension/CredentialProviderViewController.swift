#if canImport(AppKit) && canImport(AuthenticationServices)
import AppKit
import AuthenticationServices
import Foundation

final class CredentialProviderViewController: ASCredentialProviderViewController {
    private enum ProviderError: Swift.Error, LocalizedError {
        case missingUserName
        case missingUserSecret
        case missingSite

        var errorDescription: String? {
            switch self {
            case .missingUserName:
                return "Enter a user name before continuing."
            case .missingUserSecret:
                return "Enter a user secret before continuing."
            case .missingSite:
                return "No requesting site was provided by the extension context."
            }
        }
    }

    private var pendingServiceIdentifier: String?

    private lazy var statusLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Enter your Spectre user name and secret, then select Continue.")
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var siteLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Site")
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var siteField: NSTextField = {
        let field = NSTextField(string: "")
        field.placeholderString = "example.com"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var userNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "User name")
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var userNameField: NSTextField = {
        let field = NSTextField(string: "")
        field.placeholderString = "Your Full Name"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var userSecretLabel: NSTextField = {
        let label = NSTextField(labelWithString: "User Master Password")
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var userSecretField: NSSecureTextField = {
        let field = NSSecureTextField(string: "")
        field.placeholderString = "Required"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var continueButton: NSButton = {
        let button = NSButton(title: "Continue", target: self, action: #selector(completeWithCredential))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func loadView() {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        view.addSubview(siteLabel)
        view.addSubview(siteField)
        view.addSubview(userNameLabel)
        view.addSubview(userNameField)
        view.addSubview(userSecretLabel)
        view.addSubview(userSecretField)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            siteLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            siteLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            siteField.firstBaselineAnchor.constraint(equalTo: siteLabel.firstBaselineAnchor),
            siteField.leadingAnchor.constraint(equalTo: siteLabel.trailingAnchor, constant: 8),
            siteField.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            userNameLabel.topAnchor.constraint(equalTo: siteLabel.bottomAnchor, constant: 14),
            userNameLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            userNameField.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 6),
            userNameField.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            userNameField.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            userSecretLabel.topAnchor.constraint(equalTo: userNameField.bottomAnchor, constant: 12),
            userSecretLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            userSecretField.topAnchor.constraint(equalTo: userSecretLabel.bottomAnchor, constant: 6),
            userSecretField.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            userSecretField.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            continueButton.topAnchor.constraint(equalTo: userSecretField.bottomAnchor, constant: 16),
            continueButton.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            continueButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -24)
        ])

        self.view = view
        preferredContentSize = NSSize(width: 440, height: 300)
    }

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let summary = serviceIdentifiers.map(\.identifier).joined(separator: ", ")
        pendingServiceIdentifier = serviceIdentifiers
            .lazy
            .compactMap { self.normalizedSiteName(from: $0.identifier) }
            .first
        updateSiteUI()

        statusLabel.stringValue = summary.isEmpty
            ? "Waiting for a requesting service before generating a credential."
            : "Enter your Spectre details to generate a credential for: \(summary)"
    }

    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        pendingServiceIdentifier = normalizedSiteName(from: credentialRequest.credentialIdentity.serviceIdentifier.identifier)
        userNameField.stringValue = credentialRequest.credentialIdentity.user.nilIfEmpty ?? ""
        updateSiteUI()

        // Prompting for a user secret requires rendering the extension UI.
        let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userInteractionRequired.rawValue)
        extensionContext.cancelRequest(withError: error)
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        let identifier = credentialRequest.credentialIdentity.serviceIdentifier.identifier
        pendingServiceIdentifier = normalizedSiteName(from: identifier)
        userNameField.stringValue = credentialRequest.credentialIdentity.user.nilIfEmpty ?? ""
        updateSiteUI()

        statusLabel.stringValue = identifier.isEmpty
            ? "Enter your Spectre details to finish providing the credential."
            : "Select Continue to provide a Spectre-derived credential for: \(identifier)"
    }

    override func prepareInterfaceForExtensionConfiguration() {
        extensionContext.completeExtensionConfigurationRequest()
    }

    @objc
    private func completeWithCredential() {
        do {
            let credential = try makeCredential()
            extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
        } catch {
            extensionContext.cancelRequest(withError: error)
        }
    }

    private func makeCredential() throws -> ASPasswordCredential {
        let userName = userNameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userName.isEmpty else {
            throw ProviderError.missingUserName
        }

        let userSecret = userSecretField.stringValue
        guard !userSecret.isEmpty else {
            throw ProviderError.missingUserSecret
        }

        let siteName = siteField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !siteName.isEmpty else {
            throw ProviderError.missingSite
        }

        let password = try SpectreAlgorithm.password(
            for: SpectreConfiguration(
                userName: userName,
                userSecret: userSecret,
                siteName: siteName,
                resultType: .long
            )
        )

        return ASPasswordCredential(user: userName, password: password)
    }

    private func normalizedSiteName(from identifier: String) -> String? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let host = URL(string: identifier)?.host, !host.isEmpty {
            return host
        }

        return trimmed
    }

    private func updateSiteUI() {
        siteField.stringValue = pendingServiceIdentifier ?? ""
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
#endif
