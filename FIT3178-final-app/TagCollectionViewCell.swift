import UIKit

class TagCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "tagCell"

    // Exposed constants so view controller sizing uses the real values
    static let pillHorizontalPadding: CGFloat = 12.0 // per side
    static let pillVerticalPadding: CGFloat = 4.0
    static let pillFont: UIFont = UIFont.systemFont(ofSize: 14, weight: .medium)

    private static let sizingLabel: PillUILabel = {
        let l = PillUILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.horizontalPadding = TagCollectionViewCell.pillHorizontalPadding
        l.verticalPadding = TagCollectionViewCell.pillVerticalPadding
        l.font = TagCollectionViewCell.pillFont
        l.numberOfLines = 1
        l.textAlignment = .center
        l.pillColor = .systemOrange
        l.textColor = .white
        // ensure no compression during offscreen sizing
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    let pillLabel: PillUILabel = {
        let l = PillUILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.horizontalPadding = TagCollectionViewCell.pillHorizontalPadding
        l.verticalPadding = TagCollectionViewCell.pillVerticalPadding
        l.font = TagCollectionViewCell.pillFont
        l.numberOfLines = 1
        l.textAlignment = .center
        l.pillColor = .systemOrange
        l.textColor = .white
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.backgroundColor = .clear
        contentView.addSubview(pillLabel)
        NSLayoutConstraint.activate([
            pillLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pillLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            pillLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pillLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        pillLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pillLabel.text = nil
    }

    func configure(with text: String, color: UIColor? = nil, textColor: UIColor = .white) {
        pillLabel.text = text
        if let color = color { pillLabel.pillColor = color }
        pillLabel.textPillColor = textColor
    }

    // More precise sizing using an offscreen sizing PillUILabel and systemLayoutSizeFitting.
    // This uses the same layout code as the visible label so there's no mismatch.
    static func sizeForTagUsingSizingLabel(_ text: String, targetHeight: CGFloat) -> CGSize {
        let label = TagCollectionViewCell.sizingLabel
        label.text = text

        // Ensure the label uses the target height for vertical fitting.
        // systemLayoutSizeFitting will compute the needed width when vertical priority is required.
        let constrainedSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: targetHeight)

        let size = label.systemLayoutSizeFitting(
            constrainedSize,
            withHorizontalFittingPriority: .defaultLow, // allow width expansion
            verticalFittingPriority: .required         // enforce the target height
        )

        // Add safety margin to avoid any fractional/rounding differences
        let extraSafety: CGFloat = 8.0
        return CGSize(width: ceil(size.width) + extraSafety, height: targetHeight)
    }
}
