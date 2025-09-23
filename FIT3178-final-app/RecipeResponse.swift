//
//  QueryResult.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 23/9/2025.
//


import UIKit



// Top-level wrapper for TheMealDB responses
class RecipeResponse: NSObject, Decodable {
    // properties
    // The API can return "meals": null when there are no results, so keep this optional
    var recipes: [RecipeData]?
    
    
    // RecipeResponse dont have initializer, instead relying on Swift’s synthesized decoding.
}
