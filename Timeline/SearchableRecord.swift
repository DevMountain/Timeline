//
//  SearchableRecord.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    
    func matchesSearchTerm(searchTerm: String) -> Bool
}