//
//  DatabaseProtocol.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 24/9/2025.
//


import Foundation
import FirebaseAuth

enum DatabaseChange{
    case add
    case remove
    case update
}

enum ListenerType {
    case recipes
    case all
    case auth
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onRecipeListChange(change: DatabaseChange, recipeList: [Recipe])
    // called when an explicit sign-in completes successfully
//    func onAuthSuccess(user: FirebaseAuth.User)
    // called when an auth-related error occurred (signIn/signUp)
//    func onAuthError(_ error: Error)
}

protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    func addRecipe(recipeData: RecipeData) -> Recipe
    func deleteRecipe(recipe: Recipe)
    
//    func signUp(email: String, password: String) async throws -> FirebaseAuth.User
//    func signIn(email: String, password: String) async throws -> FirebaseAuth.User
//    func signOut() throws
}
