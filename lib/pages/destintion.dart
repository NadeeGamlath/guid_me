import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';


class DestinationView extends StatefulWidget {
  final String placeName;
  final double latitude;
  final double longitude;

  const DestinationView({
    Key? key,
    required this.placeName,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  LatLng? sourceLocation;
  LatLng? destinationLocation;
  List<LatLng> polylineCoordinates = [];
  Color customColor = Color(0xFF62A1AA);

  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    sourceLocation = LatLng(widget.latitude, widget.longitude);
    getLocation();
  }
  void getLocation() async {
    var location = Location();
    LocationData locationData = await location.getLocation();
    setState(() {
      currentLocation = locationData;
      destinationLocation = LatLng(locationData.latitude!, locationData.longitude!);
      getPolyPoints();
    });
  }
  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyBIPBk7RLTZxRv-TE5hIcfz3BNMMkYacLU",
      PointLatLng(sourceLocation!.latitude, sourceLocation!.longitude),
      PointLatLng(destinationLocation!.latitude, destinationLocation!.longitude),
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) => polylineCoordinates.add
        (LatLng(point.longitude, point.latitude),
      ),
      );
      setState(() {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: customColor,
        title: Text('Way to ${widget.placeName}'),
      ),
      body: currentLocation == null
          ? const Center(child: Text("Loading..."),):
      Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: GoogleMap(
              key: UniqueKey(),
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLocation!.latitude!,currentLocation!.longitude!),
                zoom: 14.5,
              ),
              polylines: {

                Polyline(
                  polylineId: PolylineId("route"),
                  color: Colors.blue, // Optional: Set polyline color
                  width: 5, // Optional: Set polyline width
                  points: polylineCoordinates,
                )
              },
              markers: {
                Marker(
                  markerId: MarkerId("source"),
                  position: sourceLocation ?? LatLng(0, 0),
                ),
                Marker(
                  markerId: MarkerId("currentLocation"),
                  position: LatLng(currentLocation!.latitude!,currentLocation!.longitude!),
                ),
                Marker(
                  markerId: MarkerId("destination"),
                  position: destinationLocation ?? LatLng(0, 0),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

}
