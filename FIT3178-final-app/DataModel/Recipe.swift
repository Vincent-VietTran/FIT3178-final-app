//
//  Recipe.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 24/9/2025.
//

import UIKit
import FirebaseFirestore

class Recipe: NSObject, Codable {
    // properties
    // id/primary key of the recipe collection in firestore
    @DocumentID var id: String?
    var recipeName: String?
    var category: String?
    var country: String?
    var instructions: String?
    var thumbnail: String?
    var tags: String?
    var tutorialLink: String?
    var sourceLink: String?
    var ingredients: [Ingredient] = []
}
