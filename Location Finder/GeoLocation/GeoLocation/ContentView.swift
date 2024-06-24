//
//  ContentView.swift
//  FindLocation
//
//  Created by MacUser on 2024-06-19.

import SwiftUI
import MapKit

struct IdentifiablePoint: Identifiable {
    let id = UUID()
    var location: MKPointAnnotation
}

struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var locations: [IdentifiablePoint] = []
    @State private var savedLocations: [IdentifiablePoint] = []
    @State private var searchResults: [MKLocalSearchCompletion] = []

    var body: some View {
        VStack {
            SearchBar(onSearch: { query in
                searchLocation(query: query)
            }, onUpdate: { query in
                updateSearchResults(query: query)
            }, searchResults: searchResults, onSelect: { completion in
                selectSearchResult(completion)
            })
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapPin(coordinate: location.location.coordinate)
            }
            .frame(height: 500)
            
            HStack {
                Button(action: zoomIn) {
                    Text("+")
                        .frame(width: 44, height: 44)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                Button(action: zoomOut) {
                    Text("-")
                        .frame(width: 44, height: 44)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                Button(action: saveLocation) {
                    Text("Save Location")
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            List {
                ForEach(savedLocations) { location in
                    HStack {
                        Text(location.location.title ?? "Unknown Location")
                        Spacer()
                        Button(action: {
                            removeLocation(location)
                        }) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    private func searchLocation(query: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let item = response.mapItems.first {
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                self.region = MKCoordinateRegion(
                    center: annotation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                self.locations = [IdentifiablePoint(location: annotation)]
            }
        }
    }
    
    private func updateSearchResults(query: String) {
        let completer = MKLocalSearchCompleter()
        completer.queryFragment = query
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    private func selectSearchResult(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let item = response.mapItems.first {
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                self.region = MKCoordinateRegion(
                    center: annotation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                self.locations = [IdentifiablePoint(location: annotation)]
            }
        }
    }

    private func saveLocation() {
        if let location = locations.first {
            savedLocations.append(location)
        }
    }

    private func removeLocation(_ location: IdentifiablePoint) {
        savedLocations.removeAll { $0.id == location.id }
    }

    private func zoomIn() {
        region.span = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta / 2,
            longitudeDelta: region.span.longitudeDelta / 2
        )
    }

    private func zoomOut() {
        region.span = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 2,
            longitudeDelta: region.span.longitudeDelta * 2
        )
    }
}


struct SearchBar: View {
    @State private var searchText = ""
    var onSearch: (String) -> Void
    var onUpdate: (String) -> Void
    var searchResults: [MKLocalSearchCompletion]
    var onSelect: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack {
            HStack {
                TextField("Search for a location", text: $searchText, onEditingChanged: { _ in
                    onUpdate(searchText)
                })
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                Button(action: {
                    onSearch(searchText)
                }) {
                    Text("Search")
                }
            }
            .padding()

            List(searchResults, id: \.self) { result in
                Text(result.title)
                    .onTapGesture {
                        onSelect(result)
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
