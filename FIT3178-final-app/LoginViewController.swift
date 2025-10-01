//
//  LoginViewController.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 24/9/2025.
//

import UIKit
// for auth features
import FirebaseAuth

class LoginViewController: UIViewController, DatabaseListener {
    
    
    var listenerType = ListenerType.auth
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
   }

   override func viewWillDisappear(_ animated: Bool) {
       super.viewWillDisappear(animated)
       databaseController?.removeListener(listener: self)
   }
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        authenticate(isSignup: false)
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        authenticate(isSignup: true)
    }
    
    private func authenticate(isSignup: Bool) {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""

            guard !email.isEmpty, !password.isEmpty else {
                displayMessage(title: "Missing fields", message: "Please enter both email and password.")
                return
            }
            guard isValidEmail(email) else {
                displayMessage(title: "Invalid email", message: "Please enter a valid email address.")
                return
            }
        
            guard isValidPassword(password) else {
                displayMessage(title: "Invalid password", message: "Password must be minimum 6 characters, at least one uppercase, one digit and one symbol")
                return
            }


            // Use async/await wrappers on databaseController (FirebaseController)
            Task {
                do {
                    if isSignup {
                        guard let user = try await databaseController?.signUp(email: email, password: password) else {
                            throw NSError(domain: "Signup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign up failed"])
                        }
                        onAuthSuccess(user: user)
                        
                    } else {
                        guard let user = try await databaseController?.signIn(email: email, password: password) else {
                            throw NSError(domain: "Login", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in failed"])
                        }
                        onAuthSuccess(user: user)
                    }
                } catch {
                    onAuthError(error)
                }
            }
        }
        

    // Valid email: format abc@gmail.com
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // Password validation: minimum 6 characters, at least one uppercase, one digit and one symbol.
    // Uses a lookahead-based regex:
    //   (?=.{6,}$)        => at least 6 characters
    //   (?=.*[A-Z])       => at least one uppercase letter
    //   (?=.*\d)          => at least one digit
    //   (?=.*[^\w\s])     => at least one symbol (non-word, non-space)
    private func isValidPassword(_ password: String) -> Bool {
        let pattern = #"(?=.{6,}$)(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s]).*"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }


    // prepare(for:) if you need to pass databaseController/reference to next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    // MARK: - Add DatabaseListener Delegate
    func onRecipeListChange(change: DatabaseChange, recipeList: [Recipe]) {
        
    }
    
    // MARK: - Auth handling
    // Called when sign-in completed (explicit sign-in). Perform segue.
    func onAuthSuccess(user: FirebaseAuth.User) {
        Task {
            performSegue(withIdentifier: "myRecipesSegue", sender: self)
        }
    }

    // Called when sign-in/up failed at the FirebaseController level
    func onAuthError(_ error: Error) {
        //            self.passwordField.text = ""
        Task {
            displayMessage(title: "Authentication Error", message: (error as NSError).localizedDescription)
        }
    }
}
