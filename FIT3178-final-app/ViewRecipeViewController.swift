//
//  ViewRecipeViewController.swift
//  FIT3178-final-app
//

import UIKit

class ViewRecipeViewController: UIViewController,
                                UITableViewDataSource, UITableViewDelegate,
                                UICollectionViewDataSource, UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout { // <- added FlowLayout delegate

    var recipe: Recipe?

    @IBOutlet weak var imageField: UIImageView!
    @IBOutlet weak var categoryField: PillUILabel!
    @IBOutlet weak var sourceField: UILabel!
    @IBOutlet weak var ingredientTable: UITableView!
    @IBOutlet weak var ingredientLabel: UILabel!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    // Add a height constraint to the tagCollectionView in Interface Builder and connect it here.
    @IBOutlet weak var tagCollectionHeightConstraint: NSLayoutConstraint!
    
    private var ingredients: [Ingredient] = []
    private var tags: [String] = []

    let CELL_INGREDIENT = "ingredientCell"
    let CELL_TAG = TagCollectionViewCell.reuseIdentifier

    override func viewDidLoad() {
        super.viewDidLoad()

        // Table setup
        ingredientTable.dataSource = self
        ingredientTable.delegate = self
        ingredientTable.tableFooterView = UIView()

        // Image view
        imageField.contentMode = .scaleAspectFill
        imageField.clipsToBounds = true

        // Collection view: horizontal flow with automatic item sizing disabled (we size in delegate)
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        // disable automatic estimated size to avoid vertical stacking issues when using sizeForItemAt
        flow.estimatedItemSize = .zero
        flow.minimumInteritemSpacing = 8
        flow.minimumLineSpacing = 8
        flow.sectionInset = .zero

        tagCollectionView.collectionViewLayout = flow
        tagCollectionView.dataSource = self
        tagCollectionView.delegate = self
        tagCollectionView.alwaysBounceHorizontal = true
        tagCollectionView.backgroundColor = .clear
        tagCollectionView.showsHorizontalScrollIndicator = false // <- hide the scroll bar

        // Register the cell class
        tagCollectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: CELL_TAG)

        // If prefer to set the fixed height in code instead of Interface Builder, set it here:
        // tagCollectionHeightConstraint.constant = 36
        
        // Defensive layout priorities: prefer the category label to keep its intrinsic size,
        // allow the tag collection to compress if necessary.
        categoryField.setContentCompressionResistancePriority(.required, for: .horizontal)
        categoryField.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        tagCollectionView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tagCollectionView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Populate recipe data if present
        guard let recipe = recipe else { return }
        
        // navigation title
        navigationItem.title = recipe.recipeName ?? "Unknown Recipe"

        // Category field
        categoryField.pillColor = .systemCyan
        categoryField.textPillColor = .white
        if let category = recipe.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            categoryField.text = category
            categoryField.isHidden = false
            
            // OPTIONAL: compute and pin width to avoid truncation if layout still compresses it.
            // Make sure category pill width is dynamic based on its content
            // This will respect a max width to avoid overflowing the screen.
            let font = categoryField.font ?? UIFont.systemFont(ofSize: 14, weight: .medium)
            let padding: CGFloat = 12 * 2 + 8
            let height = categoryField.bounds.height > 0 ? categoryField.bounds.height : 30
            let measured = ceil((category as NSString).boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: height),
                                                                     options: .usesLineFragmentOrigin,
                                                                     attributes: [.font: font],
                                                                     context: nil).width)
            let width = measured + padding
            let maxWidth = view.bounds.width - 40 // keep some safe margin from edges
            let finalWidth = min(width, maxWidth)

            // Add width constraint only if needed (prevents duplicates on repeated loads)
            if categoryField.constraints.first(where: { $0.firstAttribute == .width }) == nil {
                let widthConstraint = categoryField.widthAnchor.constraint(equalToConstant: finalWidth)
                widthConstraint.priority = .required
                widthConstraint.isActive = true
            }
        } else {
            categoryField.text = nil
            categoryField.isHidden = true
        }

        // Source
        sourceField.text = (recipe.sourceLink?.isEmpty == false) ? "Source: \(recipe.sourceLink!)" : "Source: No source found"

        // Ingredients
        ingredients = recipe.ingredients
        ingredientLabel.text = "Ingredients (\(ingredients.count))"
        ingredientTable.reloadData()

        // Tags: parse into an array and reload collection view
        setupTags(from: recipe.tags)

        // Load image
        if var imageURLString = recipe.thumbnail {
            imageURLString = imageURLString.replacingOccurrences(of: "http://", with: "https://")
            if let url = URL(string: imageURLString) { downloadImage(from: url) }
        }
    }

    private func setupTags(from rawTags: String?) {

        guard let raw = rawTags?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            tags = []
            tagCollectionView.isHidden = true
            return
        }

        // Split tags by common separators
        let separators = CharacterSet(charactersIn: ",;|")
        tags = raw.components(separatedBy: separators)
                  .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                  .filter { !$0.isEmpty }

        tagCollectionView.isHidden = tags.isEmpty
        tagCollectionView.reloadData()
        // Don't change the height here — it's fixed so the view scrolls horizontally.
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, ingredients.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = CELL_INGREDIENT
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)

        if ingredients.isEmpty {
            cell.textLabel?.text = "No ingredients found"
            cell.detailTextLabel?.text = nil
            cell.selectionStyle = .none
        } else {
            let ing = ingredients[indexPath.row]
            cell.textLabel?.text = ing.name
            if let measure = ing.measure, !measure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cell.detailTextLabel?.text = measure
            } else {
                cell.detailTextLabel?.text = nil
            }
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TAG, for: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }
        let tagText = tags[indexPath.item]
        cell.configure(with: tagText, color: .systemOrange, textColor: .white)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
        // Return item size with height matching the collection view height so only one row is used
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
            // get the vertical insets
            var verticalInsets: CGFloat = 0
            if let flow = collectionViewLayout as? UICollectionViewFlowLayout {
                verticalInsets = flow.sectionInset.top + flow.sectionInset.bottom
            }
            // height is collection's height minus vertical insets
            let targetHeight = max(1, collectionView.bounds.height - verticalInsets)

            // Use the cell's own sizing helper which already matches pill padding/font and includes a small safety margin
            let tag = tags[indexPath.item]
            let size = TagCollectionViewCell.sizeForTagUsingSizingLabel(tag, targetHeight: targetHeight)
            return size
        }
    
    

    // MARK: - Image download helper
    private func downloadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async { self.imageField.image = image }
            }
        }
        task.resume()
    }
}
