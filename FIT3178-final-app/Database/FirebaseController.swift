//
//  FirebaseController.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 24/9/2025.
//

import UIKit
// for config database
import FirebaseCore
// for auth features
import FirebaseAuth
// for interacting with firestore
import FirebaseFirestore


class FirebaseController: NSObject, DatabaseProtocol {
    
    
//    Firebase has the concept of listening to specific collections or documents for changes,
//    much like the NSFetchedResultsController
    
    // properties
    let DEFAULT_COOKBOOK_NAME = "Default Cookbook"
    var listeners = MulticastDelegate<DatabaseListener>()
    var recipeList: [Recipe]
    
//    Firebase has the concept of listening to specific collections or documents for changes, much like the NSFetchedResultsController. These collection references allow us to listen to all updates to specific collections of data
    var authController: Auth
    var database: Firestore
    var recipesRef: CollectionReference?
    var currentUser: FirebaseAuth.User?
    
   // track whether listeners have been set up (prevents double-setup)
   private var listenersInitialized = false
    
    
    override init(){
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        recipeList = [Recipe]()
        super.init()
        
        Task {
        do {
            let authDataResult = try await authController.signInAnonymously()
            currentUser = authDataResult.user
        }
        catch {
            fatalError("Firebase Authentication Failed with Error \(String(describing: error))")
        }
            self.setupRecipeListener()
        }
    }
    func addListener(listener: DatabaseListener){
        // Add listner to listeners property
        listeners.addDelegate(listener)
        
        // if lisnter type is recipes or all, call onRecipeListChange
        if listener.listenerType == .recipes || listener.listenerType == .all {
            listener.onRecipeListChange(change: .update, recipeList: recipeList)
        }
    }
    func removeListener(listener: DatabaseListener){
        listeners.removeDelegate(listener)
    }
    func cleanup(){
        
    }
    func addRecipe(recipeData: RecipeData) -> Recipe {
        // Create a recipe instance
        let recipe = Recipe()
        
        // set properties for the instance
        recipe.recipeName = recipeData.recipeName
        recipe.category = recipeData.category
        recipe.country = recipeData.country
        recipe.instructions = recipeData.instructions
        recipe.thumbnail = recipeData.thumbnail
        recipe.tags = recipeData.tags
        recipe.ingredients = recipeData.ingredients
        recipe.tutorialLink = recipeData.tutorialLink
        recipe.sourceLink = recipeData.sourceLink
        
        
        // Add to firestore
        do {
            if let recipesRef = try recipesRef?.addDocument(from: recipe) {
                recipe.id = recipesRef.documentID
            }
        } catch {
            print("Failed to serialize recipe")
        }
        
        // If succesfully add to firestore, return the added recipe as firestore object representation
        return recipe
    }
    
    func deleteRecipe(recipe: Recipe) {
        // Delete recipe by its id if found
        if let recipeId = recipe.id {
            recipesRef?.document(recipeId).delete()
        }
    }
    
//    func signUp(email: String, password: String) async throws -> FirebaseAuth.User {
//        <#code#>
//    }
//    
//    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
//        <#code#>
//    }
//    
//    func signOut() throws {
//        <#code#>
//    }
    
    // MARK: - Firebase Controller Specific Methods
    func getRecipeByID(_ id: String) -> Recipe?{
        for recipe in recipeList{
            if recipe.id == id {
                // found recipe
                return recipe
            }
        }
        // recipe not found
        return nil
    }
    func setupRecipeListener(){
        // Get firestore recipes storage reference
        recipesRef = database.collection("recipes")
        
        // Add snapshot listener, provide clsoure to be called whenever change occur
        recipesRef?.addSnapshotListener(){
            // Return immediately if snapshot not valid
            (QuerySnapshot, error) in guard let querySnapshot = QuerySnapshot else{
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // if query snapshot valid, parsing changes made on firestore
            self.parseRecipesSnapshot(snapshot: querySnapshot)
        }
    }
    
    func parseRecipesSnapshot(snapshot: QuerySnapshot){
        // oarase snapshot and make changes as required to local properties and call local listeners
        snapshot.documentChanges.forEach { (change) in
            var recipe: Recipe
            do {
                recipe = try change.document.data(as: Recipe.self)
                
                // first time snapshot called on app launch, treat all records as being added
                if change.type == .added {
                    recipeList.insert(recipe, at: Int(change.newIndex))
                }
                
                //
                else if change.type == .modified {
                    recipeList.remove(at: Int(change.oldIndex))
                }
                
                else if change.type == .removed {
                    recipeList.remove(at: Int(change.oldIndex))
                }
            } catch {
                print("Failed to decode recipe document id=\(change.document.documentID): \(error)")
                print("Raw document data for id=\(change.document.documentID): \(change.document.data())")
                // skip this change
                return
            }
            
            // once recipes been modified as requiredm call multicast invoke and update all listeners
            listeners.invoke { (listener) in
                if listener.listenerType == .recipes || listener.listenerType == .all {
                    listener.onRecipeListChange(change: .update, recipeList: recipeList)
                }
            }
        }
    }
    
}
