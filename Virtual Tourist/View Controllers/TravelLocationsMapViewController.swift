//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by Sean Williams on 30/08/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var editButton: UIBarButtonItem!
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Instantiate fetched results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")

//        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupFetchedResultsController()
        
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for pin in fetchedObjects {
                let lat = pin.latitude
                let lon = pin.longitude
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
            }
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        longPressGesture.minimumPressDuration = 1
        self.mapView.addGestureRecognizer(longPressGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            print(coordinate)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            // Persist annotation to core data
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.creationDate = Date()
            try? dataController.viewContext.save()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "photoAlbum", sender: self)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // code to center user on map pin
//        let location = locations.last
//        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: (location?.coordinate.longitude)!)
//        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)) //zoom on map
//        self.mapView.setRegion(region, animated: true)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
    }
    
}

