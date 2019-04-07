//
//  BiometricsSettingsViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-03-27.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import LocalAuthentication

class BiometricsSettingsViewController : UIViewController, Subscriber {

    var presentSpendingLimit: (() -> Void)?

    init(walletManager: WalletManager, store: Store) {
        self.walletManager = walletManager
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    private let header = RadialGradientView(backgroundColor: .darkPurple)
    private let illustration = LAContext.biometricType() == .face ? UIImageView(image: #imageLiteral(resourceName: "FaceId-Large")) : UIImageView(image: #imageLiteral(resourceName: "TouchId-Large"))
    private let label = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let switchLabel = UILabel(font: .customBold(size: 14.0), color: .darkText)
    private let toggle = GradientSwitch()
    private let separator = UIView(color: .secondaryShadow)
    private let textView = UnEditableTextView()
    private let walletManager: WalletManager
    private let store: Store
    private var rate: Rate?
    fileprivate var didTapSpendingLimit = false

    deinit {
        store.unsubscribe(self)
    }

    override func viewDidLoad() {
        store.subscribe(self, selector: { $0.currentRate != $1.currentRate }, callback: {
            self.rate = $0.currentRate
        })
        addSubviews()
        addConstraints()
        setData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didTapSpendingLimit = false
        textView.attributedText = textViewText
    }

    private func addSubviews() {
        view.addSubview(header)
        header.addSubview(illustration)
        view.addSubview(label)
        view.addSubview(switchLabel)
        view.addSubview(toggle)
        view.addSubview(separator)
        view.addSubview(textView)
    }

    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0.0, topPadding: 0.0)
        header.constrain([header.heightAnchor.constraint(equalToConstant: C.Sizes.largeHeaderHeight)])
        illustration.constrain([
            illustration.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            illustration.centerYAnchor.constraint(equalTo: header.centerYAnchor, constant: E.isIPhoneXSeries ? C.padding[4] : C.padding[2]) ])
        label.constrain([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: C.padding[2]),
            label.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[2]),
            label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -C.padding[2]) ])
        switchLabel.constrain([
            switchLabel.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            switchLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: C.padding[2]) ])
        toggle.constrain([
            toggle.centerYAnchor.constraint(equalTo: switchLabel.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: label.trailingAnchor) ])
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: switchLabel.leadingAnchor),
            separator.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: C.padding[1]),
            separator.trailingAnchor.constraint(equalTo: toggle.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0) ])
        textView.constrain([
            textView.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            textView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: C.padding[2]),
            textView.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor )])
    }

    private func setData() {
        
        view.backgroundColor = .white
        title = LAContext.biometricType() == .face ? S.FaceIDSettings.title : S.TouchIdSettings.title
        label.text = LAContext.biometricType() == .face ? S.FaceIDSettings.label : S.TouchIdSettings.label
        switchLabel.text = LAContext.biometricType() == .face ? S.FaceIDSettings.switchLabel : S.TouchIdSettings.switchLabel
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
        textView.delegate = self
        textView.attributedText = textViewText
        textView.tintColor = .primaryButton
        addFaqButton()
        let hasSetToggleInitialValue = false
        store.subscribe(self, selector: { $0.isBiometricsEnabled != $1.isBiometricsEnabled }, callback: {
            self.toggle.isOn = $0.isBiometricsEnabled
            if !hasSetToggleInitialValue {
                self.toggle.sendActions(for: .valueChanged) //This event is needed because the gradient background gets set on valueChanged events
            }
        })
        toggle.valueChanged = { [weak self] in
            guard let myself = self else { return }
            
            if LAContext.canUseBiometrics {
                myself.store.perform(action: Biometrics.setIsEnabled(myself.toggle.isOn))
                myself.textView.attributedText = myself.textViewText
            } else {
                myself.presentCantUseBiometricsAlert()
                myself.toggle.isOn = false
            }
        }
    }

    private func addFaqButton() {
        let negativePadding = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativePadding.width = -16.0
        let faqButton = UIButton.buildFaqButton(store: store, articleId: E.isIPhoneXSeries ? ArticleIds.enableFaceId : ArticleIds.enableTouchId)
        faqButton.tintColor = .white
        navigationItem.rightBarButtonItems = [negativePadding, UIBarButtonItem(customView: faqButton)]
    }

    private var textViewText: NSAttributedString {
        guard let rate = rate else { return NSAttributedString(string: "") }
        let amount = Amount(amount: walletManager.spendingLimit, rate: rate, maxDigits: store.state.maxDigits)
        let customizeText = LAContext.biometricType() == .face ? S.FaceIDSettings.customizeText : S.TouchIdSettings.customizeText
        let linkText = LAContext.biometricType() == .face ? S.FaceIDSettings.linkText : S.TouchIdSettings.linkText
        let string = "\(String(format: S.TouchIdSettings.spendingLimit, amount.bits, amount.localCurrency))\n\n\(String(format: customizeText, linkText))"
        let attributedString = NSMutableAttributedString(string: string, attributes: [
                NSAttributedStringKey.font: UIFont.customBody(size: 13.0),
                NSAttributedStringKey.foregroundColor: UIColor.darkText
            ])
        let linkAttributes = [
                NSAttributedStringKey.font: UIFont.customMedium(size: 13.0),
                NSAttributedStringKey.link: NSURL(string:"http://spending-limit")!]

        if let range = string.range(of: linkText, options: [], range: nil, locale: nil) {
            let from = range.lowerBound.samePosition(in: string.utf16)!
            let to = range.upperBound.samePosition(in: string.utf16)!
            attributedString.addAttributes(linkAttributes, range: NSRange(location: string.utf16.distance(from: string.utf16.startIndex, to: from),
                                                                          length: string.utf16.distance(from: from, to: to)))
        }

        return attributedString
    }

    fileprivate func presentCantUseBiometricsAlert() {
        let unavailableAlertTitle = LAContext.biometricType() == .face ? S.FaceIDSettings.unavailableAlertTitle : S.TouchIdSettings.unavailableAlertTitle
        let unavailableAlertMessage = LAContext.biometricType() == .face ? S.FaceIDSettings.unavailableAlertMessage : S.TouchIdSettings.unavailableAlertMessage
        let alert = UIAlertController(title: unavailableAlertTitle, message: unavailableAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BiometricsSettingsViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if LAContext.canUseBiometrics {
            guard !didTapSpendingLimit else { return false }
            didTapSpendingLimit = true
            presentSpendingLimit?()
        } else {
            presentCantUseBiometricsAlert()
        }
        return false
    }
}
