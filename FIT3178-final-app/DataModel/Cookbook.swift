//
//  Cookbook.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 24/9/2025.
//

import UIKit
import FirebaseFirestore

class Cookbook: NSObject, Codable {
    // properties
    // id/primary key of the teams collection in firestore
    @DocumentID var id: String?
    var name: String?
    var recipes: [Recipe] = []
}
