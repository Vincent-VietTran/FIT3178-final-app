//
//  ViewRecipeViewController.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 25/9/2025.
//  Updated by GitHub Copilot to display ingredients in a table view.
//

import UIKit

class ViewRecipeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var recipe: Recipe?
    
    @IBOutlet weak var imageField: UIImageView!
    @IBOutlet weak var tagField: UILabel!
    @IBOutlet weak var categoryField: UILabel!
    @IBOutlet weak var sourceField: UILabel!
    // Replace the UITextView in your storyboard with a UITableView and connect it to this outlet
    @IBOutlet weak var ingredientTable: UITableView!
    
    // Local copy of ingredients to drive the table view
    private var ingredients: [Ingredient] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Table setup
        ingredientTable.dataSource = self
        ingredientTable.delegate = self
        ingredientTable.tableFooterView = UIView() // hides empty separators
        
        // If you didn't add a prototype cell in storyboard, the code below ensures a subtitle cell is created.
        // If you DO use a prototype cell (recommended) set its identifier to "ingredientCell" and style to Subtitle.
        
        // Populate recipe data if present
        guard let recipe = recipe else { return }
        navigationItem.title = recipe.recipeName ?? "Unknown Recipe"
        tagField.text = recipe.tags ?? ""
        categoryField.text = recipe.category ?? ""
        if let src = recipe.sourceLink, !src.isEmpty {
            sourceField.text = "Source: \(src)"
        } else {
            sourceField.text = "Source: No source found"
        }
        
        // copy ingredients for table view; if empty we'll show a single "No ingredients" cell
        ingredients = recipe.ingredients
        
        ingredientTable.reloadData()
        
        // Load recipe image
        if var imageURLString = recipe.thumbnail {
            imageURLString = imageURLString.replacingOccurrences(of: "http://", with: "https://")
            if let url = URL(string: imageURLString) {
                downloadImage(from: url)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Show one row that says "No ingredients found" when the list is empty
        return max(1, ingredients.count)
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "ingredientCell"
        // Try to dequeue. If nil, create a default subtitle-style cell so detailTextLabel is available.
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)

        if ingredients.isEmpty {
            cell.textLabel?.text = "No ingredients found"
            cell.detailTextLabel?.text = nil
            cell.selectionStyle = .none
        } else {
            let ing = ingredients[indexPath.row]
            // Format: "Ingredient name" as primary, "measure" as subtitle.
            cell.textLabel?.text = ing.name
            // Put measure in detail; show nothing if nil/empty
            if let measure = ing.measure, !measure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cell.detailTextLabel?.text = measure
            } else {
                cell.detailTextLabel?.text = nil
            }
            cell.selectionStyle = .none
        }

        return cell
    }
    
    // Optional: improve visual spacing
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // Provide a custom header view with two labels: "Name" and "Measurement"
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            // Container
            let headerView = UIView()
            headerView.backgroundColor = .systemBackground

            // Name label (left)
            let nameLabel = UILabel()
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.text = "Name"
            nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
            nameLabel.textColor = .label
            headerView.addSubview(nameLabel)

            // Measurement label (right)
            let measureLabel = UILabel()
            measureLabel.translatesAutoresizingMaskIntoConstraints = false
            measureLabel.text = "Measurement"
            measureLabel.font = UIFont.boldSystemFont(ofSize: 16)
            measureLabel.textColor = .label
            measureLabel.textAlignment = .right
            headerView.addSubview(measureLabel)

            // Layout: nameLabel leading, measureLabel trailing, nameLabel trailing <= measureLabel.leading
            let margin = headerView.layoutMarginsGuide
            NSLayoutConstraint.activate([
                nameLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
                nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                measureLabel.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
                measureLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: measureLabel.leadingAnchor, constant: -8)
            ])

            return headerView
        }

        // Height for header (fixed or use automatic dimension via estimatedSectionHeaderHeight)
        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 44 // or UITableView.automaticDimension if using dynamic sizing and constraints
        }
    
    // MARK: - Image download helper
    private func downloadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.imageField.image = image
                }
            }
        }
        task.resume()
    }

}
