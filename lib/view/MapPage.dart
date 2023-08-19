import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_module/blocs/map_bloc.dart';
import 'package:map_module/models/place.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  late StreamSubscription locationSubscription;
  late StreamSubscription boundsSubscription;
  final _locationController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isTextFieldEmpty = true;

  @override
  void initState() {
    final mapBloc = Provider.of<MapBloc>(context, listen: false);

    //Listen for selected Location
    locationSubscription = mapBloc.selectedLocation.stream.listen((place) {
      if(place != null){
        _goToPlace(place);
        _animationController.reverse();
    }});

    boundsSubscription = mapBloc.bounds.stream.listen((bounds) async {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    });

    //start animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _locationController.addListener(() {
      setState(() {
        _isTextFieldEmpty = _locationController.text.isEmpty;
        if (_isTextFieldEmpty) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      });
    });
    // start animation
    _animation =
        Tween<double>(begin: 0.0, end: 300.0).animate(_animationController);
    super.initState();
  }

  @override
  void dispose() {
    final mapBloc = Provider.of<MapBloc>(context, listen: false);
    mapBloc.dispose();
    _animationController.dispose();
    locationSubscription.cancel();
    boundsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapBloc = Provider.of<MapBloc>(context);
    if (!mapBloc.isInitialized) {
      mapBloc.setCurrentLocation();
      mapBloc.isInitialized = true;
    }
    return Scaffold(
      body: (mapBloc.currentLocation == null)
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                GoogleMap(
                  scrollGesturesEnabled: true,
                  mapType: MapType.normal,
                  myLocationButtonEnabled: true,

                  initialCameraPosition: CameraPosition(
                      target: LatLng(mapBloc.currentLocation!.latitude,
                          mapBloc.currentLocation!.longitude),
                      zoom: 14),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                  },
                  markers: Set<Marker>.of(mapBloc.markers),
                ),
                AnimatedOpacity(
                  opacity: _isTextFieldEmpty
                      ? 0.0
                      : 1.0, //textfield boşsa listview görünmez olur
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    margin: EdgeInsets.only(top: 100, right: 20, left: 30),
                    height: _animation.value,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    //color: Colors.white.withOpacity(.7),
                    child: ListView.builder(
                      itemCount: mapBloc.searchResults.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(mapBloc.searchResults[index].description),
                          onTap: (){
                            print("tıklandı");
                            mapBloc.setSelectedLocation(
                              mapBloc.searchResults[index].placeId
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  width: 420,
                  height: 150,
                  child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 25.0, vertical: 54.0),
                        child: Card(
                          child: TextFormField(
                            controller: _locationController,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              print(value);
                              if (value.isNotEmpty) {
                                mapBloc.searchPlaces(value);
                                _animationController.forward();
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 15),
                              hintText:
                                  "Search",
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              suffixIcon: Icon((Icons.search_outlined),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.transparent, width: 0.0),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.transparent, width: 0.0),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
               Positioned(
                 width: MediaQuery.of(context).size.width,
                 height: 140,
                 bottom: 0,
                 child: Container(
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20) ),),
                   child: Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Wrap(
                       alignment: WrapAlignment.spaceBetween,
                       spacing: 10.0,
                       children: [
                         Center(child: Icon(Icons.maximize)),
                         FilterChip(
                           label: Text('Bank'),
                           onSelected: (val) => mapBloc.togglePlaceType(
                               'bank', val),
                           selected:
                           mapBloc.placeType  =='bank',
                           selectedColor: Colors.blue,
                         ),
                         FilterChip(
                             label: Text('Pharmacy'),
                             onSelected: (val) => mapBloc
                                 .togglePlaceType('pharmacy', val),
                             selected: mapBloc.placeType  =='pharmacy',
                             selectedColor: Colors.blue),
                         FilterChip(
                             label: Text('Restaurant'),
                             onSelected: (val) =>  mapBloc
                                 .togglePlaceType('pharmacy', val),
                             selected:
                             mapBloc.placeType  =='pharmacy',
                             selectedColor: Colors.blue),
                         FilterChip(
                             label: Text('Cafe'),
                             onSelected: (val) => mapBloc
                                 .togglePlaceType('pet_store', val),
                             selected: mapBloc.placeType  =='pet_store',
                             selectedColor: Colors.blue),
                         FilterChip(
                             label: Text('Souvenir Store'),
                             onSelected: (val) =>
                                 mapBloc
                                     .togglePlaceType('lawyer', val),
                             selected:
                             mapBloc.placeType  =='lawyer',
                             selectedColor: Colors.blue),
                         FilterChip(
                             label: Text('Market'),
                             onSelected: (val) =>
                                 mapBloc
                                     .togglePlaceType('bank', val),
                             selected:
                             mapBloc.placeType  =='bank',
                             selectedColor: Colors.blue),

                         FilterChip(
                             label: Text('Public Transport'),
                             onSelected: (val) =>
                                 mapBloc
                                     .togglePlaceType('bank', val),
                             selected:
                             mapBloc.placeType  =='bank',
                             selectedColor: Colors.blue),
                       ],
                     ),
                   ),
                 ),
               )
              ],

            ),
    );
  }

  Future<void> _goToPlace(Place place) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
        target: LatLng(
            place.geometry.location.lat ?? 0.0,
            place.geometry.location.lng ?? 0.0),
        zoom: 14.0)));
  }
}
