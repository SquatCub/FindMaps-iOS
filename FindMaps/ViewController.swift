//
//  ViewController.swift
//  FindMaps
//
//  Created by Brandon Rodriguez Molina on 30/04/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var buscadorSearchBar: UISearchBar!
    @IBOutlet weak var MapMK: MKMapView!
    
    var latitud: CLLocationDegrees?
    var longitud: CLLocationDegrees?
    var altitud: Double?
    
    // Manager para usar el GPS
    var manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        
        //Mejorar la presicion de la ubicacion
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //Monitorear ubicacion en todo momento
        manager.startUpdatingLocation()
    }

    @IBAction func ubicacionButton(_ sender: Any) {
        guard let alt = altitud else{
            return
        }
        let alerta = UIAlertController(title: "Ubicación", message: "Las coordenadas son \(latitud ?? 0) y \(longitud ?? 0), alt \(alt)", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        present(alerta, animated: true)
        
        let localizacion = CLLocationCoordinate2D(latitude: latitud!, longitude: longitud!)
        
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let region = MKCoordinateRegion(center: localizacion, span: spanMapa)
        
        MapMK.setRegion(region, animated: true)
        MapMK.showsUserLocation = true
    }
    
}

extension ViewController: CLLocationManagerDelegate, UISearchBarDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let ubicacion = locations.first else {
            return
        }
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicacion \(error)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        buscadorSearchBar.resignFirstResponder()
        
       let geocoder = CLGeocoder()
        
        if let direccion = buscadorSearchBar.text {
            geocoder.geocodeAddressString(direccion) { (places: [CLPlacemark]?, error: Error?) in
                if error == nil {
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.MapMK.setRegion(region, animated: true)
                    self.MapMK.addAnnotation(anotacion)
                    self.MapMK.selectAnnotation(anotacion, animated: true)
                }
            }
        }
    }
}
