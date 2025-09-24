//
//  RecipeData.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 23/9/2025.
//

import Foundation

// Ingredient struct to store ingredient name and its measure
struct Ingredient: Codable {
    let name: String
    let measure: String?
}

// RecipeData decodes a single recipe from TheMealDB API
class RecipeData: NSObject, Decodable {
    var recipeId: String
    var recipeName: String
    var category: String?
    var country: String?
    var instructions: String?
    var thumbnail: String?
    var tags: String?
    var tutorialLink: String?
    var sourceLink: String?
    var ingredients: [Ingredient] = []

    // Coding keys for direct properties
    private enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case recipeName = "strMeal"
        case category = "strCategory"
        case country = "strArea"
        case instructions = "strInstructions"
        case thumbnail = "strMealThumb"
        case tags = "strTags"
        case tutorialLink = "strYoutube"
        case sourceLink = "strSource"
    }

    required init(from decoder: Decoder) throws {
        // 1. Standard fields
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipeId = try container.decode(String.self, forKey: .id)
        recipeName = try container.decode(String.self, forKey: .recipeName)
        category = try? container.decode(String.self, forKey: .category)
        country = try? container.decode(String.self, forKey: .country)
        instructions = try? container.decode(String.self, forKey: .instructions)
        thumbnail = try? container.decode(String.self, forKey: .thumbnail)
        tags = try? container.decode(String.self, forKey: .tags)
        tutorialLink = try? container.decode(String.self, forKey: .tutorialLink)
        sourceLink = try? container.decode(String.self, forKey: .sourceLink)

        // 2. Dynamic ingredient/measure fields (strIngredient1...20, strMeasure1...20)
        let rawContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        // Get first 20 ingredient, measure pairs if present
        for i in 1...20 {
            // for each pair, decode the ingredient and measure field from api result
            guard let ingredientKey = DynamicCodingKey(stringValue: "strIngredient\(i)"),
                      let measureKey = DynamicCodingKey(stringValue: "strMeasure\(i)") else { continue }

                // decodeIfPresent returns String? — try? wraps any thrown error as nil, so rawName is String?
                let rawName = try? rawContainer.decodeIfPresent(String.self, forKey: ingredientKey)
                if let name = rawName?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !name.isEmpty
                {
                    let rawMeasure = try? rawContainer.decodeIfPresent(String.self, forKey: measureKey)
                    let measureTrimmed = rawMeasure?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let measure = (measureTrimmed?.isEmpty == false) ? measureTrimmed : nil
                    
                    // if ingredient name not empty and measurement is found, append that ingredient object (ingredient name, measurement) to the ingredient list
                    ingredients.append(Ingredient(name: name, measure: measure))
                }
        }
    }
}

// Helper to create dynamic coding keys for strIngredient1...20 etc.
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { return nil }
}
