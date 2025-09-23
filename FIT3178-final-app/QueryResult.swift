//
//  VolumeData.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 23/9/2025.
//


//
//  VolumeData.swift
//  "FIT3178-W05-Lab
//
//  Created by Viet Tran on 28/8/2025.
//

import UIKit




class VolumeData: NSObject, Decodable {
    // properties
    var books: [BookData]?
    
    
    // Volume data dont have initializer, instead relying on Swift’s synthesized decoding.
    // need cokingKeys inside class, in order to decode JSON from API response and look for JSON key called "items", not "books"
    //  authoritative list of properties that must be included when instances of a codable type are encoded or decoded.
    //correctly map our books property to the   items array in the JSON format
    private enum CodingKeys: String, CodingKey {
        case books = "items"
    }
}
