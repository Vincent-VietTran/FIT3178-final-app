//
//  RecipeData.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 23/9/2025.
//


import Foundation

// A single ingredient with an optional measure (e.g. "1 cup")
public struct Ingredient: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let measure: String?
}

// Public model representing a full recipe/meal
public struct Meal: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: String?
    public let area: String?
    public let instructions: String?
    public let thumbnailURL: URL?
    public let youtubeURL: URL?
    public let tags: [String]
    public let ingredients: [Ingredient]

    public var shortDescription: String {
        var parts = [String]()
        if let category = category { parts.append(category) }
        if let area = area { parts.append(area) }
        return parts.joined(separator: " • ")
    }
}

// Top-level response from TheMealDB: { "meals": [...] }
public struct MealsResponse: Decodable {
    private let meals: [RawMeal]?
}

// RawMeal decodes the loosely-structured keys from the API (strIngredient1..20, strMeasure1..20)
private struct  RawMeal: Decodable {
    // keep the raw values so we can extract dynamic ingredient keys
    private let raw: [String: String?]

    // Known fields we want to extract
    private let idMeal: String
    private let strMeal: String
    private let strCategory: String?
    private let strArea: String?
    private let strInstructions: String?
    private let strMealThumb: String?
    private let strYoutube: String?
    private let strTags: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tmp = [String: String?]()
        for key in container.allKeys {
            // decode as String? for any key
            tmp[key.stringValue] = try? container.decodeIfPresent(String.self, forKey: key)
        }
        raw = tmp

        idMeal = (raw["idMeal"] ?? "") ?? ""
        strMeal = (raw["strMeal"] ?? "") ?? ""
        strCategory = raw["strCategory"] ?? nil
        strArea = raw["strArea"] ?? nil
        strInstructions = raw["strInstructions"] ?? nil
        strMealThumb = raw["strMealThumb"] ?? nil
        strYoutube = raw["strYoutube"] ?? nil
        strTags = raw["strTags"] ?? nil
    }

    // Convert RawMeal into cleaned Meal model
    func toMeal() -> Meal {
        var ingredients = [Ingredient]()
        for i in 1...20 {
            let ingKey = "strIngredient\(i)"
            let measureKey = "strMeasure\(i)"
            let ing = raw[ingKey] ?? nil
            let measure = raw[measureKey] ?? nil

            if let ing = ing?.trimmingCharacters(in: .whitespacesAndNewlines), !ing.isEmpty {
                let measureTrimmed = measure?.trimmingCharacters(in: .whitespacesAndNewlines)
                ingredients.append(Ingredient(name: ing, measure: measureTrimmed))
            }
        }

        let tagsArray = (strTags ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Meal(
            id: idMeal,
            name: strMeal,
            category: strCategory,
            area: strArea,
            instructions: strInstructions,
            thumbnailURL: URL(string: strMealThumb ?? ""),
            youtubeURL: URL(string: strYoutube ?? ""),
            tags: tagsArray,
            ingredients: ingredients
        )
    }
}

// Dynamic coding key to iterate arbitrary JSON keys
private struct DynamicCodingKey: CodingKey, Hashable {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
