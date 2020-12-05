//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by salma apple on 1/21/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//
import Foundation
import UIKit
import MapKit
class MapViewController: UIViewController, MKMapViewDelegate {

    var  annotation: MKPointAnnotation? = nil

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapToDelete: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        tapToDelete.isHidden = true
        if let pins = loadPins() {
           displayPins(pins)
        }

    }
    func displayPins(_ pins: [Pin]) {
        for pin in pins where pin.lat != nil && pin.long != nil {
            let annotation = MKPointAnnotation()
            let latitude = Double(pin.lat!)!
            let longitude = Double(pin.long!)!
            annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! PhotoViewController
            controller.pin = pin
        }
    }
    private func loadPins() -> [Pin]? {
        var pins: [Pin]?
        do {
            try pins = CoreData.shared().fetchPins(entityName: Pin.name)
        } catch {
            print("\(#function) error:\(error)")
              displayInfo(Title: "Error", Message: "Error in fetching Pin locations: \(error)")
        }
        return pins
    }
    private func loadPin(lat: String, long: String) -> Pin? {
        let predicate = NSPredicate(format: "lat == %@ AND long == %@", lat, long)
        var pin: Pin?
        do {
            try pin = CoreData.shared().fetchPin(predicate, entityName: Pin.name)
        } catch {
            print("\(#function) error:\(error)")
            displayInfo(Title: "Error", Message: "Error in fetching location: \(error)")
        }
        return pin
    }
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            
            annotation = MKPointAnnotation()
            annotation!.coordinate = locCoord
            
            print("\(#function) Coordinate: \(locCoord.latitude),\(locCoord.longitude)")
            
            mapView.addAnnotation(annotation!)
            
        } else if sender.state == .changed {
            annotation!.coordinate = locCoord
        } else if sender.state == .ended {
            
            _ = Pin(
                lat: String(annotation!.coordinate.latitude),
                long: String(annotation!.coordinate.longitude),
                context: CoreData.shared().context
            )
            save()
            
        }
    }
    
     override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tapToDelete.isHidden = !editing
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pin!.canShowCallout = false
            pin!.pinTintColor = .red
            pin!.animatesDrop = true
        } else {
            pin!.annotation = annotation
        }
        
        return pin
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            self.displayInfo(Message: "No link defined.")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(annotation, animated: true)
        print("\(#function) lat \(annotation.coordinate.latitude) lon \(annotation.coordinate.longitude)")
        let lat = String(annotation.coordinate.latitude)
        let lon = String(annotation.coordinate.longitude)
        if let pin = loadPin(lat: lat, long: lon) {
            if isEditing {
                mapView.removeAnnotation(annotation)
                CoreData.shared().context.delete(pin)
                save()
                return
            }
            performSegue(withIdentifier: "displayAllPhoto", sender: pin)
        }
    }
    
    }
    

