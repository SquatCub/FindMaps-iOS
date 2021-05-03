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
    //Outlets de el StoryBoard
    @IBOutlet weak var buscadorSearchBar: UISearchBar!
    @IBOutlet weak var MapMK: MKMapView!
    
    // Variables a utilizar en la ubicacion
    var latitud: CLLocationDegrees?
    var longitud: CLLocationDegrees?
    var altitud: Double?
    
    // Manager para usar el GPS
    var manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Asignacion de delegado de la SearchBar
        buscadorSearchBar.delegate = self
        //asignacion de delegado y funciones para la ubicacion
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        //Mejorar la presicion de la ubicacion
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //Monitorear ubicacion en todo momento
        manager.startUpdatingLocation()
        
        MapMK.delegate = self
    }

    // Funcion para ir a nuestra ubicacion actual
    @IBAction func ubicacionButton(_ sender: Any) {
        // Variable segura para la altitud
        guard let alt = altitud else {
            return
        }
        
        // Alerta para mostrar las coordenadas actuales
        let alerta = UIAlertController(title: "Ubicación", message: "Las coordenadas son \(latitud ?? 0) y \(longitud ?? 0), alt \(alt)", preferredStyle: .alert)
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        alerta.addAction(accionAceptar)
        present(alerta, animated: true)
        
        // Variable localizacion para castear nuestras coordenadas
        let localizacion = CLLocationCoordinate2D(latitude: latitud!, longitude: longitud!)
        // Que tan separada estara nuestra camara de la ubicacion en el mapa
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        // Region que determina a donde se movera el mapa
        let region = MKCoordinateRegion(center: localizacion, span: spanMapa)
        // Se establecen los parametros para agregat la region y para mostrarla
        MapMK.setRegion(region, animated: true)
        MapMK.showsUserLocation = true
    }
    
}
// Extension del ViewController donde estan los delegados de la ubicacion y de la barra de busqueda
extension ViewController: CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate {
    // Funcion para obtener las coordenadas del usuario
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Variable segura en caso de no tener permisos no crashe la app
        guard let ubicacion = locations.first else {
            return
        }
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
    }
    // En caso de error o no tener permisos
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicacion \(error)")
    }
    // Funcion que se activa cuando se envia el contenido de la SearchBar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Ocultar teclado despues de submit
        buscadorSearchBar.resignFirstResponder()
       // Convierte coordenadas en algo amigable al usuario, servira para añadir puntos al mapa
       let geocoder = CLGeocoder()
        // En caso de tener algo en la barra de busqueda y enviarlo
        if let direccion = buscadorSearchBar.text {
            // Funcion que se le pasa la direccion (ciudad) y regresa un arreglo en caso de encontrar y otro en caso de error
            geocoder.geocodeAddressString(direccion) { (places: [CLPlacemark]?, error: Error?) in
                //Creacion del destino para renderizar ruta
                guard let destinoRuta = places?.first?.location else {
                    return
                }
                
                //Si no hay error
                if error == nil {
                    //Obtiene el primer lugar del arreglo
                    let lugar = places?.first
                    //Creacion de la anotacion para incluir al mapa, se le establecen coordenadas y un titulo
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    //El span que nos determinara que tan alejada estara la vista del usuario del mapa
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    //Se obtiene la region pasandole las coordenadas que se le dieron a la anotacion y el span
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    //Asignamos al mapa una region con animacion
                    self.MapMK.setRegion(region, animated: true)
                    //Agregamos la anotacion
                    self.MapMK.addAnnotation(anotacion)
                    //En caso de seleccionar alguna anotacion se anima
                    self.MapMK.selectAnnotation(anotacion, animated: true)
                    
                    //Mandar llara al trazar ruta
                    self.trazarRuta(coordenadasDestino: destinoRuta.coordinate)
                }
            }
        }
    }
    
    func trazarRuta(coordenadasDestino: CLLocationCoordinate2D) {
        guard let coordenadasOrigen = manager.location?.coordinate else {
            return
        }
        // Crear lugar de origen-destino
        let origenPlaceMark = MKPlacemark(coordinate: coordenadasOrigen)
        let destinoPlaceMark = MKPlacemark(coordinate: coordenadasDestino)

        // Crear objeto mapkit item
        let origenItem = MKMapItem(placemark: origenPlaceMark)
        let destinoItem = MKMapItem(placemark: destinoPlaceMark)
        
        // Solicitud de ruta
        let solicitudDestino = MKDirections.Request()
        solicitudDestino.source = origenItem
        solicitudDestino.destination = destinoItem
        // Definir como se va a viajar
        solicitudDestino.transportType = .automobile
        solicitudDestino.requestsAlternateRoutes = true
        
        let direcciones = MKDirections(request: solicitudDestino)
        direcciones.calculate { (respuesta, error) in
            // Desenvolver la respuesta
            guard let respuestaSegura = respuesta else {
                if let error = error {
                    print("Error al calcular la ruta \(error.localizedDescription)")
                }
                return
            }
            // Si success
            //Obtenemos las rutas trazadas y las eliminamos
            let overlay = self.MapMK.overlays
            self.MapMK.removeOverlays(overlay)
            //Obtenemos la nueva ruta
            let ruta = respuestaSegura.routes[0]
            // Agregar superposicion
            self.MapMK.addOverlay(ruta.polyline)
            self.MapMK.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
            let distancia = ruta.distance/1000
            // Alerta para mostrar la distancia
            let alerta = UIAlertController(title: "Distancia", message: "La distancia es de \(distancia) KM", preferredStyle: .alert)
            let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
            alerta.addAction(accionAceptar)
            self.present(alerta, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderizado.strokeColor = .white
        return renderizado
    }
}
