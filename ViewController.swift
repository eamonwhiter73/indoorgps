/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Primary view controller for what is displayed by the application.
    In this class we configure an ARKit app to display content using iBeacons
    with known locations.
*/

import CoreLocation
import Foundation
import MapKit
import SceneKit
import ARKit

/**
    Primary view controller for what is displayed by the application.

    In this class we configure an MKMapView to display a floorplan, recieve
    location updates to determine floor number, as well as provide a few helpful
    debugging annotations.

    We will also show how to highlight a region that you have defined in PDF
    coordinates but not Latitude & Longitude.
*/
class ViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var locationManager: LocationManager!

    /// This property remembers which floor we're on.
    var lastFloor: CLFloor!

    var coordinateConverter: CoordinateConverter!
    var scalePDF: CGFloat!
    var scalePOS: CGFloat!
    var origin: Array! = []
    var m: matrix_float4x4 = matrix_float4x4()
    var mRotate: matrix_float4x4 = matrix_float4x4()
    var originAsMapPoint: MKMapPoint = MKMapPoint()
    var currentHeading: CLLocationDirection!
    var proximityA: CLLocationAccuracy!
    var proximityB: CLLocationAccuracy!
    var proximityC: CLLocationAccuracy!
    var proximityD: CLLocationAccuracy!
    var proximityE: CLLocationAccuracy!
    var myPosition: Point!
    var lastPosition: Point!
    var scale: Float!
    var locationA: [String:Any]!
    var locationB: [String:Any]!
    var locationC: [String:Any]!
    var locationD: [String:Any]!
    var locationE: [String:Any]!
    var array: Array<[String:Any]>!
    var returnSet: Set<IntersectPoints>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = LocationManager()
        locationManager.delegate = self
        
        returnSet = Set()
        
        // === Configure our floorplan.
        sceneView = ARSCNView()
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        // Set the scene to the view
        /*
            We setup a pair of anchors that will define how the floorplan image
            maps to geographic co-ordinates.
        */
        
        
        
        //beacon 49398
        let anchor1 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(42.246960,-71.175248), pdfPoint: CGPoint(x: 4.0355, y: 3.7817))
        
        //DSDTECH
        let anchor2 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(42.246882,-71.175270), pdfPoint: CGPoint(x: 3.0203, y: -0.2538))

        let anchorPair = GeoAnchorPair(fromAnchor: anchor1, toAnchor: anchor2)

        coordinateConverter = CoordinateConverter(anchors: anchorPair)
        
        let transformerFromPDFToMk = coordinateConverter.transformerFromPDFToMk()
        
        print("\(transformerFromPDFToMk.tx) -- tx")
        print("\(transformerFromPDFToMk.ty) -- ty")
        origin = [transformerFromPDFToMk.tx, transformerFromPDFToMk.ty]
        
        //custom scale to mitigate z-fighting (using a smaller world)
        scale = Float(coordinateConverter.unitSizeInMeters) * 2000
        
        //translation matrix for `setWorldOrigin`
        m = matrix_float4x4()
        m.columns.3 = [Float(transformerFromPDFToMk.tx) / scale, 0.0, Float(transformerFromPDFToMk.ty) / scale, 1.0]
        m.columns.2 = [0.0, 0.0, 1.0, 0.0]
        m.columns.1 = [0.0, 1.0, 0.0, 0.0]
        m.columns.0 = [1.0, 0.0, 0.0, 0.0]
        
        /*mRotate = matrix_float4x4()
        mRotate.columns.3 = [0.0, 0.0, 0.0, 1.0]
        mRotate.columns.2 = [Float(sin(angle)), 0.0, Float(cos(angle)), 0.0]
        mRotate.columns.1 = [0.0, 1.0, 0.0, 0.0]
        mRotate.columns.0 = [Float(cos(angle)), 0.0, Float(-sin(angle)), 0.0]*/
        
        /*var mRotateZ = matrix_float4x4()
        mRotateZ.columns.3 = [0.0, 0.0, 0.0, 1.0]
        mRotateZ.columns.2 = [0.0, 0.0, 1.0, 0.0]
        mRotate.columns.1 = [Float(-sin(angle)), Float(cos(angle)), 0.0, 0.0]
        mRotate.columns.0 = [Float(cos(angle)), Float(sin(angle)), 0.0, 0.0]*/
        
        /*var mmRotate = SCNMatrix4()
        mm.m41 = 0.0; mm.m42 = 0.0; mm.m43 = 0.0; mm.m44 = 1.0
        mm.m31 = Float(sin(angle)); mm.m32 = 0.0; mm.m33 = Float(cos(angle)); mm.m34 = 0.0
        mm.m21 = 0.0; mm.m22 = 1.0; mm.m23 = 0.0; mm.m34 = 0.0
        mm.m11 = Float(cos(angle)); mm.m22 = 0.0; mm.m23 = Float(-sin(angle)); mm.m34 = 0.0*/
        
        for node in scene.rootNode.childNodes {
            
            node.position = SCNVector3Make(-Float(transformerFromPDFToMk.tx) / scale + node.position.x, node.position.y, -Float(transformerFromPDFToMk.ty) / scale + node.position.z)
            
            node.runAction(SCNAction .rotateBy(x: 0.0, y: .pi, z: 0.0, duration: 0.0))
        }
        
        sceneView.scene = scene
        view.addSubview(sceneView)
        
        //the transformation translates the origin of the MKMapKit world to my actual world coordinate location (in MK coordinate system. 1 meter is 1 unit.
        sceneView.session.setWorldOrigin(relativeTransform: m)
        
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        //continually update the nodes position, but only if you are in a new spot
        lastPosition = Point(xx: 0.0, yy: 0.0)
        if myPosition != nil && myPosition != lastPosition {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            for node in scene.rootNode.childNodes {
                
                node.simdPosition = simd_float3(-Float(Float(myPosition.x! - lastPosition.x!) + node.position.x), node.position.y, -Float(Float(myPosition.y! - lastPosition.y!) + node.position.z))
                
                lastPosition = myPosition
            }
            SCNTransaction.commit()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(node) --- node in renderer did remove")
        print("\(anchor) --- anchor in renderer did remove")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("\(node) --- node in renderer did update")
        print("\(anchor) --- anchor in renderer did update")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let configuration = sceneView.session.configuration {
            sceneView.session.run(configuration)
        }
        else {
            let config = ARWorldTrackingConfiguration()
            
            //load gravity and heading to handle true north orientation
            config.worldAlignment = .gravityAndHeading
            
            sceneView.session.run(config)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*
            For additional debugging, you may prefer to use non-satellite
            (standard) view instead of satellite view. If so, uncomment the line
            below. However, satellite view allows you to zoom in more closely
            than non-satellite view so you probably do not want to leave it this
            way in production.
        */
        //mapView.mapType = MKMapTypeStandard
    }
    
    override func viewDidLayoutSubviews() {
        sceneView.frame = self.view.frame
    }
}

extension ViewController: LocationManagerDelegate {
    
    func locationManagerDidUpdateLocation(_ locationManager: CLLocationManager, location: CLLocation) {
        //iBeacons being used instead of location updates
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: CLLocationManager, heading: CLHeading, accuracy: CLLocationDirection) {
        self.currentHeading = heading.trueHeading
    }
    
    func locationManagerDidEnterRegion(_ locationManager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("did enter region --- \(region)")
    }
    
    func locationManagerDidExitRegion(_ locationManager: CLLocationManager, didExitRegion region: CLRegion) {
        print("did exit region --- \(region)")
    }
    
    func locationManagerDidDetermineState(_ locationManager: CLLocationManager, didDetermineState state: CLRegionState, region: CLRegion) {
        //setup in class
    }
    
    func locationManagerDidRangeBeacons(_ locationManager: CLLocationManager, beacons: [CLBeacon], region: CLBeaconRegion) {
        print("\(beacons) + beacons for ranging")
        if beacons.count > 0 {
            for beacon in beacons {
                let major = CLBeaconMajorValue(truncating: beacon.major)
                let minor = CLBeaconMinorValue(truncating: beacon.minor)
                
                print("major: \(major)")
                print("minor: \(minor)")
                print("accuracy: \(beacon.accuracy)")
                
                switch beacon.proximity {
                case .immediate:
                    print("--- immediate ---")
                case .near:
                    print("--- near ---")
                case .far:
                    print("--- far ---")
                case .unknown:
                    print("--- proximity unknown ---")
                }
                
                guard beacon.accuracy != -1.0 else {
                    return
                }
                
                //distance from `point1`
                if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0004) {
                    self.proximityA = beacon.accuracy
                }
                    
                //distance from `point2`
                else if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0002) {
                    self.proximityB = CLLocationAccuracy(beacon.accuracy)
                }
                    
                //distance from `point3`
                else if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0005) {
                    self.proximityC = CLLocationAccuracy(beacon.accuracy)
                }
                
                //distance from `point4`
                else if (beacon.proximityUUID.uuidString == "12345678-B644-4520-8F0C-720EAF059935" && beacon.minor == 0x0003) {
                    self.proximityD = CLLocationAccuracy(beacon.accuracy)
                }
                
                //distance from `point5`
                else if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0001) {
                    self.proximityE = CLLocationAccuracy(beacon.accuracy)
                }
            }
                
            if (proximityA != nil && proximityB != nil && proximityC != nil && proximityD != nil && proximityE != nil) {
                
                locationA = ["point": Point(xx: 4.0355, yy: 3.7817), "radius": proximityA]
                locationB = ["point": Point(xx: 3.0203, yy: -0.2538), "radius": proximityD]
                locationC = ["point": Point(xx: 0.01, yy: -3.9593), "radius": proximityB]
                locationD = ["point": Point(xx: -2.7411, yy: -0.3807), "radius": proximityE]
                locationE = ["point": Point(xx: -5.3807, yy: 3.0964), "radius": proximityC]
                
                array = [locationA, locationB, locationC, locationD, locationE]
                
                var z = 0
                while z < 5 {
                    var n = 0
                    while n < 4 {
                        if (n + 1 != z) {
                            let r1Bigger = array[z]["radius"] as! Double > array[array.index(after: n)]["radius"] as! Double ? array[z]["radius"] : array[array.index(after: n)]["radius"]
                            let r2Smaller = array[z]["radius"] as! Double > array[array.index(after: n)]["radius"] as! Double ? array[array.index(after: n)]["radius"] : array[z]["radius"]
                            
                            let x = Trilateration.calculateIntersections(p1: array[z]["point"] as! Point, p2: array[array.index(after: n)]["point"] as! Point, r1Bigger: Float(r1Bigger as! Double), r2Smaller: Float(r2Smaller as! Double), n: [array[z]["point"] as! Point, array[array.index(after: n)]["point"] as! Point])
                            
                            if returnSet != [] {
                                for y in returnSet {
                                    if((y.points[0].x == x.points[0].x && y.points[0].y == x.points[0].y && y.points[1].x == x.points[1].x && y.points[1].y == x.points[1].y) || (y.points[0].x == x.points[1].x && y.points[0].y == x.points[1].y && y.points[1].x == x.points[0].x && y.points[1].y == x.points[0].y))
                                    {
                                        print("\(y.points) --- removed")
                                        returnSet.remove(y)
                                    }
                                }
                            }
                            
                            if(!(x.P1.x?.isNaN)! && !((x.P1.y?.isNaN)!) && !((x.P2.x?.isNaN)!) && !((x.P2.y?.isNaN)!)) {
                                returnSet.insert(x)
                            }
                        }
                        n+=1
                    }
                    z+=1
                }
                
                for x in returnSet {
                    print("x1: \(String(describing: x.P1.x)) ----- y1: \(String(describing: x.P1.y)) ----- x2: \(String(describing: x.P2.x)) ----- y2: \(String(describing: x.P2.y)) ----- points: \(x.points)")
                }
                
                //This method finds our position in local space based on three known points (in local space) and three known distances (in local space)
                //let myPosition: Point = Trilateration.trilateration(point1: Point(xx: 0.74, yy: 1.75), point2: Point(xx: -0.47, yy: -2.72), point3: Point(xx: -1.75, yy: 1.88), r1: proximityA, r2: proximityB, r3: proximityC)
            
                //print("\(String(describing: myPosition.x)) --- x")
                //print("\(String(describing: myPosition.y)) --- y")
            
                print("------ NODE POSITION ------")
                print(sceneView.scene.rootNode.childNodes[0].position.x)
                print(sceneView.scene.rootNode.childNodes[0].position.z)
            }
        }
    }
}

/*var currentPacket = Set<CLBeacon>()
 
 //distance from `point1`
 if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0004) {
 if (!currentPacket.contains(beacon) && beacon.accuracy < 20.00) {
 currentPacket.update(with: beacon)
 }
 else if (beacon.accuracy < 20.00 && beacon.accuracy < currentPacket[currentPacket.index(of: beacon)!].accuracy) {
 currentPacket.remove(currentPacket[currentPacket.index(of: beacon)!])
 currentPacket.update(with: beacon)
 }
 }
 
 //distance from `point2`
 else if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0002) {
 if (!currentPacket.contains(beacon) && beacon.accuracy < 20.00) {
 currentPacket.update(with: beacon)
 }
 else if (beacon.accuracy < 20.00 && beacon.accuracy < currentPacket[currentPacket.index(of: beacon)!].accuracy) {
 currentPacket.remove(currentPacket[currentPacket.index(of: beacon)!])
 currentPacket.update(with: beacon)
 }
 }
 
 //distance from `point3`
 else if (beacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && beacon.minor == 0x0005) {
 if (!currentPacket.contains(beacon) && beacon.accuracy < 20.00) {
 currentPacket.update(with: beacon)
 }
 else if (beacon.accuracy < 20.00 && beacon.accuracy < currentPacket[currentPacket.index(of: beacon)!].accuracy) {
 currentPacket.remove(currentPacket[currentPacket.index(of: beacon)!])
 currentPacket.update(with: beacon)
 }
 }
 
 if currentPacket.count == 3 {
 for beacon in currentPacket {
 if (beacon.minor == 0x0005) {
 self.proximityC = beacon.proximity.rawValue
 }
 else if (beacon.minor == 0x0002) {
 self.proximityB = beacon.proximity.rawValue
 }
 else if (beacon.minor == 0x0004) {
 self.proximityA = beacon.proximity.rawValue
 }
 }
 }*/
