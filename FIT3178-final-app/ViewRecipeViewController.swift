//
//  ViewRecipeViewController.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 25/9/2025.
//

import UIKit

class ViewRecipeViewController: UIViewController {
    
    var recipe: Recipe?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Populate recipe data if found one
        guard let recipe = recipe else {return}
        navigationItem.title = recipe.recipeName ?? "Unkown Recipe"
        tagField.text = recipe.tags ?? ""
        categoryField.text = recipe.category ?? ""
        sourceField.text = recipe.sourceLink ?? "No source found"
        var recipeIngredients = recipe.ingredients
        if recipeIngredients.isEmpty {
            ingredientField.text = "No ingredients found"
        }
        else {
            for ingredient in recipeIngredients {
                ingredientField.text.append(ingredient.measure ?? "" + ingredient.name)
            }
        }
        
        // Load recipe image
        if var imageURLString = recipe.thumbnail {
                    imageURLString = imageURLString.replacingOccurrences(of: "http://", with: "https://")
                    if let url = URL(string: imageURLString) {
                        downloadImage(from: url)
                    }
                }
    }
    

    @IBOutlet weak var imageField: UIImageView!
    @IBOutlet weak var tagField: UILabel!
    @IBOutlet weak var categoryField: UILabel!
    @IBOutlet weak var sourceField: UILabel!
    @IBOutlet weak var ingredientField: UITextView!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Image download helper
    private func downloadImage(from url: URL) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
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
