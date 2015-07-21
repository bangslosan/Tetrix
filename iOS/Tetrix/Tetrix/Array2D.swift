//
//  Array2D.swift
//  Tetrix
//
//  Created by Leonardo Cardoso on 7/20/15.
//  Copyright (c) 2015 leocardz. All rights reserved.
//

import Foundation


class Array2D<T> {

    let columns: Int
    let rows: Int
    
    var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(count:rows * columns, repeatedValue: nil)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[(row * columns) + column]
        }
        set(newValue) {
            array[(row * columns) + column] = newValue
        }
    }
    
}