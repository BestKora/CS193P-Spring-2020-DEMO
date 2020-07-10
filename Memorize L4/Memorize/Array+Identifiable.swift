//
//  Array+Identifiable.swift
//  Memorize
//
//  Created by CS193P Instructor on 04/06/2020.
//  Copyright © 2020 cs193p instructor. All rights reserved.
//

import Foundation

extension Array where Element: Identifiable {
    func firstIndex (matching: Element)-> Int? {
          for index in 0..<self.count {
              if self[index].id == matching.id {
                  return index
              }
          }
           return nil
       }
}
