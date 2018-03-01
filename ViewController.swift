/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Primary view controller for what is displayed by the application.
                In this class we configure an MKMapView to display a floorplan,
                recieve location updates to determine floor number, as well as
                provide a few helpful debugging annotations.
                We will also show how to highlight a region that you have defined in
                PDF coordinates but not Latitude  Longitude.
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
    /// Outlet for the map view in the storyboard.
    var sceneView: ARSCNView!
    /// Outlet for the visuals switch at the lower-right of the storyboard.
    //@IBOutlet weak var debugVisualsSwitch: UISwitch!

    /**
        To enable user location to be shown in the map, go to Main.storyboard,
        select the Map View, open its Attribute Inspector and click the checkbox
        next to User Location

        The user will need to authorize this app to use their location either by 
        enabling it in Settings or by selecting the appropriate option when 
        prompted.
    */
    var locationManager: LocationManager!

    //var hideBackgroundOverlayAlpha: CGFloat!

    /// Helper class for managing the scroll & zoom of the MapView camera.
    //var visibleMapRegionDelegate: VisibleMapRegionDelegate!

    /// Store the data about our floorplan here.

    //var debuggingOverlays: [MKOverlay]!
    //var debuggingAnnotations: [MKAnnotation]!

    /// This property remembers which floor we're on.
    var lastFloor: CLFloor!

    /**
        Set to false if you want to turn off auto-scroll & auto-zoom that snaps
        to the floorplan in case you scroll or zoom too far away.
    */
    //var snapMapViewToFloorplan: Bool!

    /**
        Set to true when we reveal the MapKit tileset (by pressing the trashcan
        button).
     */
    //var mapKitTilesetRevealed = false

    /// Call this to reset the camera.
    /*@IBAction func resetCamera(_ sender: AnyObject) {
        visibleMapRegionDelegate.mapViewResetCameraToFloorplan(mapView)
    }*/

    /**
        When the trashcan hasn't yet been pressed, this toggles the debug
        visuals. Otherwise, this toggles the floorplan.
    */
    /*@IBAction func toggleDebugVisuals(_ sender: AnyObject) {
        if (sender.isKind(of: UISwitch.classForCoder())) {
            let senderSwitch: UISwitch = sender as! UISwitch
            /*
                If we have revealed the mapkit tileset (i.e. the trash icon was
                pressed), toggle the floorplan display off.
            */
            if (mapKitTilesetRevealed == true) {
                if (senderSwitch.isOn == true) {
                    showFloorplan()
                } else {
                    hideFloorplan()
                }
            } else {
                if (senderSwitch.isOn == true) {
                    showDebugVisuals()
                } else {
                    hideDebugVisuals()
                }
            }
        }
    }*/

    /**
        Remove all the overlays except for the debug visuals. Forces the debug
        visuals switch off.
    */
    /*@IBAction func revealMapKitTileset(_ sender: AnyObject) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        // Show labels for restaurants, schools, etc.
        mapView.showsPointsOfInterest = true
        // Show building outlines.
        mapView.showsBuildings = true
        mapKitTilesetRevealed = true
        // Set switch to off.
        debugVisualsSwitch.setOn(false, animated: true)
        showDebugVisuals()
    }*/
    var coordinateConverter: CoordinateConverter!
    var scalePDF: CGFloat!
    var scalePOS: CGFloat!
    var origin: Array! = []
    var m: matrix_float4x4 = matrix_float4x4()
    var mRotate: matrix_float4x4 = matrix_float4x4()
    var originAsMapPoint: MKMapPoint = MKMapPoint()
    var currentHeading: CLLocationDirection!
    var angle: CLLocationDirection!
    var latestAccuracyA: CLLocationAccuracy!
    var latestAccuracyB: CLLocationAccuracy!
    var latestAccuracyC: CLLocationAccuracy!
    var myPosition: Point!
    var lastPosition: Point!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = LocationManager()
        locationManager.delegate = self
        
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
        let anchor1 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(42.246960,-71.175248), pdfPoint: CGPoint(x: -1.7512, y: -1.8781))
        
        let anchor2 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(42.246876,-71.175277), pdfPoint: CGPoint(x: 1.02, y: -1.75))

        let anchorPair = GeoAnchorPair(fromAnchor: anchor1, toAnchor: anchor2)

        coordinateConverter = CoordinateConverter(anchors: anchorPair)
        
        let transformerFromPDFToMk = coordinateConverter.transformerFromPDFToMk()
        
        print("\(transformerFromPDFToMk.tx) -- tx")
        print("\(transformerFromPDFToMk.ty) -- ty")
        origin = [transformerFromPDFToMk.tx, transformerFromPDFToMk.ty]
        
        angle = coordinateConverter.getUprightMKMapCameraHeading()
        print("\(angle) --- angle")
        
        m = matrix_float4x4()
        m.columns.3 = [Float(transformerFromPDFToMk.tx) / (Float(coordinateConverter.unitSizeInMeters) * 2000), 0.0, Float(transformerFromPDFToMk.ty) / (Float(coordinateConverter.unitSizeInMeters) * 2000), 1.0]
        m.columns.2 = [0.0, 0.0, 1.0, 0.0]
        m.columns.1 = [0.0, 1.0, 0.0, 0.0]
        m.columns.0 = [1.0, 0.0, 0.0, 0.0]
        
        mRotate = matrix_float4x4()
        mRotate.columns.3 = [0.0, 0.0, 0.0, 1.0]
        mRotate.columns.2 = [Float(sin(angle)), 0.0, Float(cos(angle)), 0.0]
        mRotate.columns.1 = [0.0, 1.0, 0.0, 0.0]
        mRotate.columns.0 = [Float(cos(angle)), 0.0, Float(-sin(angle)), 0.0]
        
        var mRotateZ = matrix_float4x4()
        mRotateZ.columns.3 = [0.0, 0.0, 0.0, 1.0]
        mRotateZ.columns.2 = [0.0, 0.0, 1.0, 0.0]
        mRotate.columns.1 = [Float(-sin(angle)), Float(cos(angle)), 0.0, 0.0]
        mRotate.columns.0 = [Float(cos(angle)), Float(sin(angle)), 0.0, 0.0]
        
        var sim = simd_float3()
        sim.x = Float(transformerFromPDFToMk.tx)
        sim.y = 0.0
        sim.z = Float(transformerFromPDFToMk.ty)
        
        var simd = simd_float4x4()
        simd.columns.3 = [sim.x, sim.y, sim.z, 1.0]
        simd.columns.2 = [0.0, 0.0, 1.0, 0.0]
        simd.columns.1 = [0.0, 1.0, 0.0, 0.0]
        simd.columns.0 = [1.0, 0.0, 0.0, 0.0]
        
        var mm = SCNMatrix4()
        mm.m41 = sim.x; mm.m42 = sim.y; mm.m43 = sim.z; mm.m44 = 1.0
        mm.m31 = 0.0; mm.m32 = 0.0; mm.m33 = 1.0; mm.m34 = 0.0
        mm.m21 = 0.0; mm.m22 = 1.0; mm.m23 = 0.0; mm.m34 = 0.0
        mm.m11 = 1.0; mm.m22 = 0.0; mm.m23 = 0.0; mm.m34 = 0.0
        
        var mmRotate = SCNMatrix4()
        mm.m41 = 0.0; mm.m42 = 0.0; mm.m43 = 0.0; mm.m44 = 1.0
        mm.m31 = Float(sin(angle)); mm.m32 = 0.0; mm.m33 = Float(cos(angle)); mm.m34 = 0.0
        mm.m21 = 0.0; mm.m22 = 1.0; mm.m23 = 0.0; mm.m34 = 0.0
        mm.m11 = Float(cos(angle)); mm.m22 = 0.0; mm.m23 = Float(-sin(angle)); mm.m34 = 0.0
        
        var mmm = SCNMatrix4()
        mm.m41 = 0.0; mm.m42 = 0.0; mm.m43 = 0.0; mm.m44 = 1.0
        mm.m31 = 0.0; mm.m32 = 0.0; mm.m33 = 1.0; mm.m34 = 0.0
        mm.m21 = 0.0; mm.m22 = 1.0; mm.m23 = 0.0; mm.m34 = 0.0
        mm.m11 = 1.0; mm.m22 = 0.0; mm.m23 = 0.0; mm.m34 = 0.0
        
        var identity = matrix_float4x4()
        identity.columns.3 = [0.0, 0.0, 0.0, 1.0]
        identity.columns.2 = [0.0, 0.0, 1.0, 0.0]
        identity.columns.1 = [0.0, 1.0, 0.0, 0.0]
        identity.columns.0 = [1.0, 0.0, 0.0, 0.0]
        
        sceneView.scene = scene
        view.addSubview(sceneView)
        
        //sceneView.session.setWorldOrigin(relativeTransform: transformed)
        sceneView.session.setWorldOrigin(relativeTransform: m)
        
        /*sceneView.scene.rootNode.position = SCNVector3Make(-Float(transformerFromPDFToMk.tx) / (Float(coordinateConverter.unitSizeInMeters) * 2000), sceneView.scene.rootNode.position.y, -Float(transformerFromPDFToMk.ty) / (Float(coordinateConverter.unitSizeInMeters) * 2000))*/
        
        //sceneView.scene.rootNode.transform = SCNMatrix4Mult(mm, mmRotate)
        
        for node in scene.rootNode.childNodes {
            
            /*let sim3 = simd_float3()
            sim.x = -Float(transformerFromPDFToMk.tx) / Float(coordinateConverter.unitSizeInMeters) + node.position.x / Float(coordinateConverter.unitSizeInMeters)
            sim.y = node.position.y / Float(coordinateConverter.unitSizeInMeters)
            sim.z = -Float(transformerFromPDFToMk.ty) / Float(coordinateConverter.unitSizeInMeters) + node.position.z / Float(coordinateConverter.unitSizeInMeters)*/
            
            node.position = SCNVector3Make(-Float(transformerFromPDFToMk.tx) / (Float(coordinateConverter.unitSizeInMeters) * 2000) + node.position.x, node.position.y, -Float(transformerFromPDFToMk.ty) / (Float(coordinateConverter.unitSizeInMeters) * 2000) + node.position.z)
            
            node.runAction(SCNAction .rotateBy(x: 0.0, y: .pi, z: 0.0, duration: 0.0))
        }
        
        //floorLevel = level
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        lastPosition = Point(xx: 0.0, yy: 0.0)
        if myPosition != nil {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            for node in scene.rootNode.childNodes {
                //var seqArray: Array<SCNAction> = []
                
                node.simdPosition = /*SCNVector3Make(-Float(Float(myPosition.x!) + Float(node.position.x)), node.position.y, -Float(Float(myPosition.y!) + Float(node.position.z)))*/simd_float3(-Float(Float(myPosition.x! - lastPosition.x!) + node.position.x), node.position.y, -Float(Float(myPosition.y! - lastPosition.y!) + node.position.z))
                
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
        
    }
    
    func locationManagerDidRangeBeacons(_ locationManager: CLLocationManager, beacons: [CLBeacon], region: CLBeaconRegion) {
        print("\(beacons) + beacons for ranging")
        if beacons.count > 0 {
            let nearestBeacon = beacons.first!
            let major = CLBeaconMajorValue(truncating: nearestBeacon.major)
            let minor = CLBeaconMinorValue(truncating: nearestBeacon.minor)
            
            print("major: \(major)")
            print("minor: \(minor)")
            print("accuracy: \(nearestBeacon.accuracy)")
            
            switch nearestBeacon.proximity {
            case .immediate:
                print("--- immediate ---")
            case .near:
                print("--- near ---")
            case .far:
                print("--- far ---")
            case .unknown:
                print("--- proximity unknown ---")
            }
            
            guard nearestBeacon.accuracy != -1.0 else {
                return
            }
            
            //DSD-TECH
            if (nearestBeacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && nearestBeacon.minor == 0x0004) {
                self.latestAccuracyA = CLLocationAccuracy(nearestBeacon.proximity.rawValue)
            }
                
                //i9
            else if (nearestBeacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && nearestBeacon.minor == 0x0002) {
                self.latestAccuracyB = CLLocationAccuracy(nearestBeacon.proximity.rawValue)
            }
                
                //i4
            else if (nearestBeacon.proximityUUID.uuidString == "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" && nearestBeacon.minor == 0x0005) {
                self.latestAccuracyC = CLLocationAccuracy(nearestBeacon.proximity.rawValue)
            }
            
            if (latestAccuracyA != nil && latestAccuracyB != nil && latestAccuracyC != nil) {
                let myPosition: Point = Trilateration.trilateration(point1: Point(xx: 0.74, yy: 1.75), point2: Point(xx: -0.47, yy: -2.72), point3: Point(xx: -1.75, yy: 1.88), r1: latestAccuracyA, r2: latestAccuracyB, r3: latestAccuracyC)
            
                print("\(String(describing: myPosition.x)) --- x")
                print("\(String(describing: myPosition.y)) --- y")
            
                //SCNTransaction.begin()
                //SCNTransaction.animationDuration = 0.1
                //let j = SCNMatrix4MakeTranslation(-Float(myPosition.x!), 0.0, -Float(myPosition.y!))
                                print("------ NODE POSITION ------")
                print(sceneView.scene.rootNode.childNodes[0].position.x)
                print(sceneView.scene.rootNode.childNodes[0].position.z)
            }
        }
    }
}
