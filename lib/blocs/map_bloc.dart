import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_module/models/geometry.dart';
import 'package:map_module/models/location.dart';
import 'package:map_module/models/place.dart';
import 'package:map_module/models/place_search.dart';
import 'package:map_module/services/geolocator_service.dart';
import 'package:map_module/services/marker_service.dart';
import 'package:map_module/services/places_service.dart';


class MapBloc with ChangeNotifier{
  final geolocatorService = GeolocatorService();
  final placeService = PlaceService();
  final markerService = MarkerService();


  //variables
  bool isInitialized = false;
  Position? currentLocation;
  List<PlaceSearch> searchResults = [];
  List<Marker> markers= [];
  StreamController<Place> selectedLocation = StreamController<Place>();
  StreamController<LatLngBounds> bounds = StreamController<LatLngBounds>();
  Place? selectedLocationStatic;
  String? placeType;



  MapBloc(){
    setCurrentLocation();
  }

  setCurrentLocation() async{
    currentLocation = await geolocatorService.getCurrentLocation();
    selectedLocationStatic = Place(
      name:"",
        geometry: Geometry(
            location: Location(
                lat: currentLocation?.latitude,
                lng: currentLocation?.longitude)),
      );

    addCurrentLocationMarker();
    notifyListeners();

  }


  searchPlaces(String searchTerm)async{
    searchResults = await placeService.getAutoComplete(searchTerm);
    notifyListeners();
  }

  setSelectedLocation(String placeId) async {
    selectedLocation.add(await placeService.getPlace(placeId));
    selectedLocationStatic = await placeService.getPlace(placeId);
    searchResults = [];
    notifyListeners();
  }




    togglePlaceType(String value, bool selected) async {
      if (selected) {
        placeType = value;
      } else {
        placeType = null;
      }

      if (placeType != null) {
        var places = await placeService.getPlaces(
          selectedLocationStatic?.geometry.location.lat ?? 0.0,
          selectedLocationStatic?.geometry.location.lng ?? 0.0,
          placeType!,
        );

        markers = [];
        if (places.length > 0) {
          var newMarker = markerService.createMarkerFromPlace(places[0]);
          markers.add(newMarker);
        }

        var locationMarker = markerService.createMarkerFromPlace(selectedLocationStatic!);
        markers.add(locationMarker);


        var _bounds = markerService.bounds(Set<Marker>.of(markers));
        bounds.add(_bounds!);

      }
      notifyListeners();
    }


  void addCurrentLocationMarker() {
    if (currentLocation != null) {
      var locationMarker = markerService.createMarkerFromPlace(
        Place(
          name: "Current Location",
          geometry: Geometry(
            location: Location(
              lat: currentLocation!.latitude,
              lng: currentLocation!.longitude,
            ),
          ),
        ),
      );
      markers.add(locationMarker);
    }
  }


  @override
  void dispose() {
    selectedLocation.close();
    bounds.close();
    super.dispose();
  }
}