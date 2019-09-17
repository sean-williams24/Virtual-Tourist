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
    @IBOutlet var deletePinsView: UIView!
    
    var dataController: DataController!
    var longPressGesture = UILongPressGestureRecognizer()
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var tappedPin: MKAnnotation!
    var selectedPin: Pin!
    var deleting = false
    let latKey = "lat key"
    let lonKey = "lon key"
    let latDeltaKey = "lat delta key"
    let lonDeltaKey = "lon delta key"
    
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Instantiate fetched results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func loadAnnotations() {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Retrieve userDefault value for map region and zoom level and return view to previous state
        
        let latDouble = UserDefaults.standard.double(forKey: latKey)
        let lonDouble = UserDefaults.standard.double(forKey: lonKey)
        let latDelta = UserDefaults.standard.double(forKey: latDeltaKey)
        let lonDelta = UserDefaults.standard.double(forKey: lonDeltaKey)
        
        let lat = CLLocationDegrees(latDouble)
        let lon = CLLocationDegrees(lonDouble)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let viewRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        mapView.setRegion(viewRegion, animated: true)

        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
    
        setupFetchedResultsController()
        loadAnnotations()
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
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
    
    
    //MARK: - Persist map view region and zoom level in user defaults
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let lat = mapView.centerCoordinate.latitude
        let lon = mapView.centerCoordinate.longitude
        let latDelta = mapView.region.span.latitudeDelta
        let lonDelta = mapView.region.span.longitudeDelta
        
        UserDefaults.standard.set(lat, forKey: latKey)
        UserDefaults.standard.set(lon, forKey: lonKey)
        UserDefaults.standard.set(latDelta, forKey: latDeltaKey)
        UserDefaults.standard.set(lonDelta, forKey: lonDeltaKey)
    }
    
    
    //MARK: - Map annoation and pin selection methods
    
    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Persist annotation to core data
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.creationDate = Date()
            try? dataController.viewContext.save()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        tappedPin = view.annotation
        
        // If selected pin coordinates match pin coordinates of persisted pin, set selectedPin property
        
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation?.coordinate.longitude
        
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for pin in fetchedObjects {
                if pin.latitude == lat && pin.longitude == lon {
                    // If editing state is true, tapping pins should removed them
                    if deleting {
                        dataController.viewContext.delete(pin)
                        try? dataController.viewContext.save()
                        mapView.removeAnnotation(tappedPin)
                    } else {
                        self.selectedPin = pin
                        performSegue(withIdentifier: "photoAlbum", sender: self)
                    }
                }
            }
        }
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass data to photo album vc
        if let vc = segue.destination as? PhotoAlbumViewController {
            vc.dataController = dataController
            vc.pin = selectedPin
        }
    }
    

    // Set editing state, show/hide deleting pins view
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deleting = !deleting
        if editing {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.frame.origin.y -= self.deletePinsView.frame.height
            })
            longPressGesture.isEnabled = false
        } else {
            UIView.animate(withDuration: 0.5) {
                self.view.frame.origin.y += self.deletePinsView.frame.height
            }
            longPressGesture.isEnabled = true
        }
    }
}


extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Pin instances")
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        
        switch type {
        case .insert:
            mapView.addAnnotation(annotation)
            
        case .delete:
            mapView.removeAnnotation(annotation)
            
        case .update:
            mapView.removeAnnotation(annotation)
            mapView.addAnnotation(annotation)
            
        case .move:
            // N.B. The fetched results controller was set up with a single sort descriptor that produced a consistent ordering for its fetched Point instances.
            fatalError("How did we move a Point? We have a stable sort.")
        @unknown default:
            fatalError()
        }
    }
}
