//
//  PillUILabel.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 1/10/2025.
//

import UIKit

@IBDesignable
class PillUILabel: UILabel {
    
    @IBInspectable
    var horizontalPadding: CGFloat = 12.0 {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    @IBInspectable
    var verticalPadding: CGFloat = 4.0 {
        didSet { invalidateIntrinsicContentSize() }
    }

    // allow configuring the pill color from IB or code
    @IBInspectable
    var pillColor: UIColor = .secondarySystemFill {
        didSet {
            backgroundColor = pillColor
        }
    }
    
    // allow configuring the text color from IB or code
    @IBInspectable
    var textPillColor: UIColor = .secondarySystemFill {
        didSet {
            textColor = textPillColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupPillAppearance()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupPillAppearance()
    }
    
    override var intrinsicContentSize: CGSize {
        let originalSize = super.intrinsicContentSize
        return CGSize(
            width: originalSize.width + horizontalPadding * 2,
            height: originalSize.height + verticalPadding * 2
        )
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        super.drawText(in: rect.inset(by: insets))
    }
    
    private func setupPillAppearance() {
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
        // Use the configurable color
        backgroundColor = pillColor
        textColor = textPillColor
        numberOfLines = 1
        textAlignment = .center
        font = UIFont.systemFont(ofSize: 15, weight: .regular)
    }

    // If you ever set a dynamic color and need to react to appearance changes (light/dark),
    // uncomment and use this:
    /*
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Re-apply pillColor in case it's a dynamic color that changed
        backgroundColor = pillColor
    }
    */
}
