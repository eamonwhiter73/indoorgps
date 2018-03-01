//
//  Utilities.swift
//  Trilateration
//
//  Created by Tharindu Ketipearachchi on 1/17/18.
//  Copyright © 2018 Tharindu Ketipearachchi. All rights reserved.
//

import UIKit

class Point: NSObject {
    
    var x: Double?
    var y: Double?
    
    init(xx:Double, yy:Double) {
        x = xx
        y = yy
    }
}

class Trilateration: NSObject {
    
    static func trilateration(point1: Point, point2: Point, point3: Point, r1: Double, r2:Double, r3: Double) -> Point {
        
        let x1 = point1.x
        let y1 = point1.y
        let x2 = point2.x
        let y2 = point2.y
        let x3 = point3.x
        let y3 = point3.y
        let d1 = r1
        let d2 = r2
        let d3 = r3
        
        let chunkA = (pow(d1,2) - pow(d2, 2)) - (pow(x1!, 2) - pow(x2!, 2)) - (pow(y1!, 2) - pow(y2!, 2))
        let littleChunkA = 2 * (y3! - y1!)
        let chunkB = ((pow(d1,2) - pow(d3, 2)) - (pow(x1!, 2) - pow(x3!, 2)) - (pow(y1!, 2) - pow(y3!, 2)))
        let littleChunkB = 2 * (y2! - y1!)
        let chunkI = 2 * (x2! - x1!)
        let chunkK = 2 * (x3! - x1!)
        
        let littleChunkE = 2 * (x2! - x1!)
        
        let X = ((chunkA * littleChunkA) - (chunkB * littleChunkB)) / ((littleChunkA * chunkI) - (littleChunkB * chunkK))
        let Y = ((chunkB * littleChunkE) - (chunkA * chunkK)) / ((littleChunkA * chunkI) - (littleChunkB * chunkK))
        
        let location = Point(xx: X,yy: Y)
        
        return location
    }
}


