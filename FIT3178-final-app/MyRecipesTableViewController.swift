//
//  MyRecipesTableViewController.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 23/9/2025.
//

import UIKit
import FirebaseAuth

class MyRecipesTableViewController: UITableViewController, DatabaseListener {
    
    
    
    // MARK: Auth functions
    func onAuthSuccess(user: FirebaseAuth.User) {
        
    }
    
    func onAuthError(_ error: any Error) {
        
    }
    
    @objc func signOutTapped() {
        do {
            try databaseController?.signOut()
                    
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            
            // Create the same transition as navigation back button
            let transition = CATransition()
            transition.duration = 0.3  // Same duration as navigation controller
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft  // Slides from left (like back button)
            
            // Apply transition to navigation controller
            self.navigationController?.view.layer.add(transition, forKey: nil)
            self.navigationController?.setViewControllers([loginVC], animated: false)
            
        } catch {
            // Handle error (show alert)
            displayMessage(title: "Error", message: "Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // properties
    var listenerType: ListenerType = .recipes
    // table cell resuable id
    let CELL_RECIPE = "recipeCell"
    let NUM_SECTIONS = 1
    var allRecipes = [Recipe]()
    
    // Have reference to the database controller
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // get a reference to the database from appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Add Sign Out button to navigation bar
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Sign Out",
                style: .plain,
                target: self,
                action: #selector(signOutTapped)
            )
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return NUM_SECTIONS
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allRecipes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_RECIPE, for: indexPath)
        let recipe = allRecipes[indexPath.row]
        cell.textLabel?.text = recipe.recipeName
        cell.detailTextLabel?.text = recipe.category

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recipe = allRecipes[indexPath.row]
            databaseController?.deleteRecipe(recipe: recipe)
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "viewRecipeSegue" {
            let destination = segue.destination as! ViewRecipeViewController
            destination.recipe = allRecipes[(tableView.indexPathForSelectedRow?.row)!]
        }
    }

    // MARK: - Database listener methods
    
    func onRecipeListChange(change: DatabaseChange, recipeList: [Recipe]) {
        allRecipes = recipeList
        tableView.reloadData()
    }
    
    // Add this controller as listener to database controller when view appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    // remove this controller as listener to database controller when view disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
}
