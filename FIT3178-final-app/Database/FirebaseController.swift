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
            // setup listener for this (anonymous) user
            self.setupRecipeListener()
            // mark as initialized because we've set up a snapshot listener already
            listenersInitialized = true
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
    
    // MARK: - Recipe CRUD
    // Add a recipe only if no other document in the CURRENT USER'S subcollection has the same recipeId field.
    // The recipe will be stored under: users/{uid}/recipes/{autoDocId}
    func addRecipe(recipeData: RecipeData, completion: @escaping (Result<Recipe, Error>) -> Void) {
        // Ensure we have an authenticated user
        guard let user = currentUser else {
            let err = NSError(domain: "FirebaseController", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
            completion(.failure(err))
            return
        }
        
        let mealId = recipeData.recipeId
        
        // Reference to the user's recipes subcollection
        let userRecipesRef = database.collection("users").document(user.uid).collection("recipes")
        
        // 1) Query user's subcollection to check for existing recipe with same MealDB id
        userRecipesRef
            .whereField("recipeId", isEqualTo: mealId)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let count = snapshot?.documents.count, count > 0 {
                    // Duplicate — return specific error code so callers can show appropriate message
                    let err = NSError(domain: "FirebaseController", code: 409, userInfo: [NSLocalizedDescriptionKey: "A recipe with that id already exists in your collection"])
                    completion(.failure(err))
                    return
                }

                // 2) No duplicate found — create the document in user's recipes subcollection
                guard let self = self else {
                    let err = NSError(domain: "FirebaseController", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal error"])
                    completion(.failure(err))
                    return
                }

                // Build dictionary to write (only non-nil fields)
                var data: [String: Any] = [
                    "recipeId": recipeData.recipeId,
                    "recipeName": recipeData.recipeName,
                    "createdAt": Timestamp(date: Date())
                ]
                if let category = recipeData.category { data["category"] = category }
                if let country = recipeData.country { data["country"] = country }
                if let instructions = recipeData.instructions { data["instructions"] = instructions }
                if let thumbnail = recipeData.thumbnail { data["thumbnail"] = thumbnail }
                if let tags = recipeData.tags { data["tags"] = tags }
                if let tutorial = recipeData.tutorialLink { data["tutorialLink"] = tutorial }
                if let source = recipeData.sourceLink { data["sourceLink"] = source }
                // map ingredients to array of dicts
                data["ingredients"] = recipeData.ingredients.map { ["name": $0.name, "measure": $0.measure ?? ""] }

                // Use an auto-generated document id in the user's subcollection
                let docRef = userRecipesRef.document()
                docRef.setData(data) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        // build Recipe object to return (matches your Recipe model)
                        let added = Recipe()
                        added.recipeId = recipeData.recipeId
                        added.recipeName = recipeData.recipeName
                        added.category = recipeData.category
                        added.country = recipeData.country
                        added.instructions = recipeData.instructions
                        added.thumbnail = recipeData.thumbnail
                        added.tags = recipeData.tags
                        added.tutorialLink = recipeData.tutorialLink
                        added.sourceLink = recipeData.sourceLink
                        added.ingredients = recipeData.ingredients
                        added.id = docRef.documentID
                        completion(.success(added))
                    }
                }
            }
    }
    
    func deleteRecipe(recipe: Recipe) {
        // Delete recipe by its id from the user's recipes subcollection if found
        guard let recipeId = recipe.id, let user = currentUser else { return }
        database.collection("users").document(user.uid).collection("recipes").document(recipeId).delete()
    }
    
    // MARK: - Firebase Auth actions (async/await)
    // Create account, log user in after successful
    func signUp(email: String, password: String) async throws -> FirebaseAuth.User {
            let result = try await authController.createUser(withEmail: email, password: password)
            self.currentUser = result.user

            // create user doc
            let userDoc = database.collection("users").document(result.user.uid)
            try await userDoc.setData([
                "email": result.user.email ?? "User",
                "createdAt": Timestamp(date: Date())
            ])
            
            // When a real user signs up we should switch the recipes listener to listen to their subcollection.
            // Remove previous listener by reassigning recipesRef and adding the new snapshot listener.
            // Note: we don't maintain an explicit listener handle here — reassigning recipesRef will mean
            // the previous listener remains if one was added; to keep this simple we only set up a new listener if not already initialized.
            if !listenersInitialized {
                self.setupRecipeListener()
                listenersInitialized = true
            } else {
                // If listeners were previously initialized (for anonymous user), switch to the new user's subcollection
                self.setupRecipeListener()
            }
            return result.user
    }

    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await authController.signIn(withEmail: email, password: password)
        self.currentUser = result.user
        print("Current user: \( self.currentUser?.uid ?? "nil")")

        // Ensure we listen to the authenticated user's recipes subcollection
        if !listenersInitialized {
            self.setupRecipeListener()
            listenersInitialized = true
        } else {
            // Switch listener to the signed-in user's subcollection
            self.setupRecipeListener()
        }
        return result.user
    }

    func signOut() throws {
        try authController.signOut()
        // state listener above will see no user and react
    }
    
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
        // If we have a user, listen to that user's recipes subcollection, otherwise fallback to top-level "recipes"
        if let user = currentUser {
            recipesRef = database.collection("users").document(user.uid).collection("recipes")
        } else {
            // fallback (shouldn't normally happen because we sign in anonymously in init)
            recipesRef = database.collection("recipes")
        }
        
        // Remove any existing local snapshot handling state
        recipeList.removeAll()
        
        // Add snapshot listener, provide closure to be called whenever change occur
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
        // parse snapshot and make changes as required to local properties and call local listeners
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
                    // replace at oldIndex
                    if recipeList.indices.contains(Int(change.oldIndex)) {
                        recipeList.remove(at: Int(change.oldIndex))
                    }
                    recipeList.insert(recipe, at: Int(change.newIndex))
                }
                
                else if change.type == .removed {
                    if recipeList.indices.contains(Int(change.oldIndex)) {
                        recipeList.remove(at: Int(change.oldIndex))
                    }
                }
            } catch {
                print("Failed to decode recipe document id=\(change.document.documentID): \(error)")
                print("Raw document data for id=\(change.document.documentID): \(change.document.data())")
                // skip this change
                return
            }
            
            // once recipes been modified as required, call multicast invoke and update all listeners
            listeners.invoke { (listener) in
                if listener.listenerType == .recipes || listener.listenerType == .all {
                    listener.onRecipeListChange(change: .update, recipeList: recipeList)
                }
            }
        }
    }
    
}
