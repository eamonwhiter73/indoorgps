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

class IntersectPoints: NSObject {
    var P1: Point
    var P2: Point
    var points: Array<Point>
    
    init(p1:Point, p2:Point, poin: Array<Point>) {
        P1 = p1
        P2 = p2
        points = poin
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
    
    /*static func multiPointTrilateration(point1: Point, point2: Point, point3: Point, point4: Point, point5: Point, r1: Double, r2:Double, r3: Double, r4: Double, r5: Double) -> Point {
        
        
        
        return Point()
    }*/
    
    static func calculateIntersections(p1: Point, p2: Point, r1Bigger: Float, r2Smaller: Float, n: Array<Point>) -> IntersectPoints {
        
        let distanceBetween = sqrt(pow((p1.x! - p2.x!), 2) + pow((p1.y! - p2.y!), 2))
        
        print("\(distanceBetween) --- distanceBetween")
        //print("\(p1.x) --- \(p1.y) --- \(p2.x) --- \(p2.y)")
        var r2SmallerAdjusted: Float = r2Smaller
        var r1BiggerAdjusted: Float = r1Bigger
        if (Float(distanceBetween) > r1Bigger + r2Smaller) {
            print("distanceBetween > rBigger + r2Smaller")
            //r2SmallerAdjusted = Float(distanceBetween) - r1Bigger
        }
        else if (Float(distanceBetween) < abs(r1Bigger - r2Smaller)) {
            print("distanceBetween < abs(r1Bigger - r2Smaller)")
            if r1Bigger > r2Smaller {
                r1BiggerAdjusted = Float(distanceBetween) + r2Smaller - 0.1
            }
            else if (r2Smaller > r1Bigger){
                r2SmallerAdjusted = Float(distanceBetween) + r1Bigger - 0.1
            }
        }
        else if (Float(distanceBetween) == 0) {
            print("distanceBetween == 0")
        }
        else if (r1Bigger == r2Smaller) {
            print("r1Bigger == r2Smaller")
            //r2SmallerAdjusted = r2Smaller + 0.01
        }
        
        let a = (pow(r1BiggerAdjusted, 2) - pow(r2SmallerAdjusted, 2) + Float(pow(distanceBetween, 2)) ) / (2 * Float(distanceBetween))
        
        let hSquared = pow(r1BiggerAdjusted, 2) - pow(a, 2)
        let numer = a * Float((p2.x! - p1.x!) - (p2.y! - p1.y!))
        let crossingPointX = (Float(p1.x!) + numer) / Float(distanceBetween)
        let crossingPointY = (Float(p1.y!) + numer) / Float(distanceBetween)
        let axisIntersect = Point(xx: Double(crossingPointX), yy: Double(crossingPointY))
        
        let x3a = Float(axisIntersect.x!) + sqrt(hSquared) * Float( p2.y! - p1.y! ) / Float(distanceBetween)
        let x3b = Float(axisIntersect.x!) - sqrt(hSquared) * Float( p2.y! - p1.y! ) / Float(distanceBetween)
        let y3a = Float(axisIntersect.y!) - sqrt(hSquared) * Float( p2.x! - p1.x! ) / Float(distanceBetween)
        let y3b = Float(axisIntersect.y!) + sqrt(hSquared) * Float( p2.x! - p1.x! ) / Float(distanceBetween)
        
        let intersectPoints = IntersectPoints(p1: Point(xx: Double(x3a), yy: Double(y3a)), p2: Point(xx: Double(x3b), yy: Double(y3b)), poin: [n[0], n[1]])
        
        return intersectPoints
    }
}


