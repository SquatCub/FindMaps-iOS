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
    }
    
}

extension ViewController: CLLocationManagerDelegate {
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
}
