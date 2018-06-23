//
//  PaperPhraseViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-25.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

class StartPaperPhraseViewController : UIViewController {
    
    init(store: Store, callback: @escaping () -> Void) {
        self.store = store
        self.callback = callback
        let buttonTitle = UserDefaults.walletRequiresBackup ? S.StartPaperPhrase.buttonTitle : S.StartPaperPhrase.againButtonTitle
        button = ShadowButton(title: buttonTitle, type: .primary)
        super.init(nibName: nil, bundle: nil)
    }
    
    private let label = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let separator = UIView(color: .secondaryShadow)
    private let textView = UnEditableTextView()
    private let button: ShadowButton
    private let illustration = UIImageView(image: #imageLiteral(resourceName: "PaperKey"))
    private let pencil = UIImageView(image: #imageLiteral(resourceName: "Pencil"))
    private let store: Store
    private let header = RadialGradientView(backgroundColor: .pink, offset: 64.0)
    private let footer = UILabel.wrapping(font: .customBody(size: 13.0), color: .secondaryGrayText)
    private let callback: () -> Void
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        addSubviews()
        addConstraints()
        setData()
        button.tap = { [weak self] in
            self?.callback()
        }
        if let writePaperPhraseDate = UserDefaults.writePaperPhraseDate {
            let df = DateFormatter()
            df.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
            footer.text = String(format: S.StartPaperPhrase.date, df.string(from: writePaperPhraseDate))
            footer.textAlignment = .center
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.attributedText = textViewText
    }
    
    private func addSubviews() {
        view.addSubview(header)
        header.addSubview(illustration)
        illustration.addSubview(pencil)
        view.addSubview(label)
        view.addSubview(separator)
        view.addSubview(textView)
        view.addSubview(button)
        view.addSubview(footer)
    }
    
    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0.0, topPadding: 0.0)
        header.constrain([
            header.constraint(.height, constant: 220.0) ])
        illustration.constrain([
            illustration.constraint(.width, constant: 64.0),
            illustration.constraint(.height, constant: 84.0),
            illustration.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            illustration.centerYAnchor.constraint(equalTo: header.centerYAnchor, constant: E.isIPhoneX ? C.padding[4] : C.padding[2]) ])
        pencil.constrain([
            pencil.constraint(.width, constant: 32.0),
            pencil.constraint(.height, constant: 32.0),
            pencil.constraint(.leading, toView: illustration, constant: 44.0),
            pencil.constraint(.top, toView: illustration, constant: -4.0) ])
        label.constrain([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: C.padding[2]),
            label.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[2]),
            label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -C.padding[2]) ])
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            separator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: C.padding[1]),
            separator.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0) ])
        textView.constrain([
            textView.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            textView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: C.padding[2]),
            textView.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor )])
        button.constrain([
            button.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -C.padding[2]),
            button.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            button.constraint(.height, constant: C.Sizes.buttonHeight) ])
        footer.constrain([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -C.padding[2]),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
    }
    
    private func setData() {
        
        view.backgroundColor = .white
        label.text = S.StartPaperPhrase.body
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
        textView.delegate = self
        textView.attributedText = textViewText
        textView.tintColor = .primaryButton
    }
    
    private var textViewText: NSAttributedString {
        let customizeText = S.StartPaperPhrase.customizeText
        let linkText = S.StartPaperPhrase.linkText
        let string = "\(String(format: customizeText, linkText))"
        let attributedString = NSMutableAttributedString(string: string, attributes: [
            NSAttributedStringKey.font: UIFont.customBody(size: 16.0),
            NSAttributedStringKey.foregroundColor: UIColor.darkText
            ])
        let linkAttributes = [
            NSAttributedStringKey.font: UIFont.customMedium(size: 16.0),
            NSAttributedStringKey.link: NSURL(string:"https://monawallet.net/terms")!]
        
        if let range = string.range(of: linkText, options: [], range: nil, locale: nil) {
            let from = range.lowerBound.samePosition(in: string.utf16)!
            let to = range.upperBound.samePosition(in: string.utf16)!
            attributedString.addAttributes(linkAttributes, range: NSRange(location: string.utf16.distance(from: string.utf16.startIndex, to: from),
                                                                          length: string.utf16.distance(from: from, to: to)))
        }
        
        return attributedString
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StartPaperPhraseViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
