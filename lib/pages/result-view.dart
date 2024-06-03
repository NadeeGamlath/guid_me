import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/rating/gf_rating.dart';
import 'package:getwidget/size/gf_size.dart';
import 'destintion.dart';

import 'controll.dart';
List<dynamic> placesList = [];

class ResultView extends StatefulWidget {
  final String buttonText;
  final String keyword;
  final String type;

  ResultView({
    Key? key,
    required this.buttonText,
    required this.keyword,
    required this.type,
  }) : super(key: key);

  @override
  _ResultViewState createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {

  bool filterByRating = false;
  bool filterByDistance = false;
  Color customColor = Color(0xFF62A1AA);

  @override
  Widget build(BuildContext context) {
    double radius = 9000; // Default value for radius

    return Scaffold(
      appBar: AppBar(
        backgroundColor: customColor,
        title: Text('${widget.buttonText} in this area'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: filterByRating,
                  onChanged: (value) async {
                    setState(() {
                      filterByRating = value!;
                    });
                    if (filterByRating) {
                      List<dynamic> sortedPlaces = await fetchNearbyPlacesSortedByRating();
                      setState(() {
                        placesList = sortedPlaces;
                      });
                    }
                  },
                ),
                Text('Filter by Rating'),
                SizedBox(width: 10),
                Checkbox(
                  value: filterByDistance,
                  onChanged: (value) async {
                    setState(() {
                      filterByDistance = value!;
                    });
                    if (filterByDistance) {
                      List<dynamic> sortedPlaces = await fetchNearbyPlacesSortedByDistance();
                      setState(() {
                        placesList = sortedPlaces;
                      });
                    }
                    // Apply distance filter logic here
                  },
                ),
                Text('Filter by Distance'),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 20),
            FutureBuilder(
              future: filterByRating ? fetchNearbyPlacesSortedByRating() : (filterByDistance ? fetchNearbyPlacesSortedByDistance() : fetchNearbyPlaces(widget.keyword, widget.type, radius)),
              builder: (context, snapshot) {
                //snapshot = current state eka save karana storage ekk
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  List<dynamic> places = snapshot.data as List<dynamic>;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      return buildCard(places[index]);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<dynamic>> fetchNearbyPlaces(String keyword, String type,
    double radius) async {
  late Controller controller = Controller();
  final position = await controller.getCurrentPosition();
  double longitude = position.longitude;
  double latitude = position.latitude;
  try {
    final places = await controller.searchNearbyPlaces(keyword, type,
        radius, latitude, longitude);
    placesList = List.from(places);

    return places;
  } catch (e) {
    throw Exception('Error fetching nearby places: $e');
  }
}

Future<List<dynamic>> fetchNearbyPlacesSortedByRating() async {
  try{
    // Create a copy of the global places list
    List<dynamic> sortedPlaces = List.from(placesList);

    // Sort places by descending rating
    sortedPlaces.sort((a, b) {
      double ratingA = (a['rating'] ?? 0).toDouble(); // Convert to double
      double ratingB = (b['rating'] ?? 0).toDouble();
      return ratingB.compareTo(ratingA);
    });

    print(sortedPlaces);
    return sortedPlaces;
  } catch(e){
    throw Exception('Error sorting places by rating: $e');
  }

}

Future<List<dynamic>> fetchNearbyPlacesSortedByDistance() async {
  late Controller controller = Controller();
  try {
    // Create a copy of the global places list
    List<dynamic> sortedPlaces = List.from(placesList);

    // Calculate distance for each place
    for (dynamic place in sortedPlaces) {
      double distance = await controller.getDistanceToPlace(
        place['geometry']['location']['lat'],
        place['geometry']['location']['lng'],
      );
      print('distance');
      print(distance);
      place['distance'] = distance; // Add distance to each place
    }

    // Sort places by distance
    sortedPlaces.sort((a, b) {
      double distanceA = a['distance'] as double;
      print('############################');
      print(distanceA);
      print('############################');
      double distanceB = b['distance'] as double;
      return distanceA.compareTo(distanceB);
    });

    print(sortedPlaces);
    return sortedPlaces;
  } catch (e) {
    throw Exception('Error sorting places by distance: $e');
  }
}

Widget buildCard(dynamic place) {
  late Controller controller = Controller();
  return FutureBuilder<List<dynamic>>(
    future: Future.wait([
      controller.getPlaceRating(place['place_id']),
      controller.getPlaceOpeningHours(place['place_id']),
      controller.getDistanceToPlace(
        place['geometry']['location']['lat'],
        place['geometry']['location']['lng'],
      ),
    ]),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        // Handle the error without displaying it to the user
        // You can log the error for debugging purposes
        print('Error fetching data: ${snapshot.error}');
        return Container(); // Return an empty container or null
      } else {
        List<dynamic> data = snapshot.data!;
        double rating = data[0] as double;
        Map<String, String> openingHours = data[1] as Map<String, String>;
        double distance = data[2] as double;
        print(data[2]);

        if (data==[]) {
          return Container(
            height: 150,
            child: Center(
              child: Text('Sorry! Location not found in this area'),
            ),
          );
        }

        return Container(
          height: 230,
          child: Card(
            elevation: 9,
            shape: RoundedRectangleBorder(
              // borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            child: ListTile(
              dense: false,
              title: Text(
                place['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['vicinity'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  //Star marks
                  GFRating(
                    value: rating,
                    size: GFSize.SMALL, // Adjust size as needed
                    color: const Color(0xFFFBBC04), onChanged: (double rating) {  }, // Star color
                  ),
                  Text('Rating: ${rating.toStringAsFixed(1)}'),
                  Text('Opening Hours: ${getFormattedOpeningHours(openingHours)}'),
                  Text('Distance: ${distance.toStringAsFixed(1)} km'),
                ],
              ),
              trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Navigate to a new screen with the place name
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DestinationView(
                              placeName: place['name'],
                              latitude: place['geometry']['location']['lat'],
                              longitude: place['geometry']['location']['lng'],
                            ),
                          ),
                        );
                      },
                      // color: Colors.transparent,
                      icon: Image.asset(
                        'images/location-icon.png',
                        width: 50,
                        height: 50,
                      ),
                      // text: 'Guide Me',
                    ),
                  ]
              ),
            ),
          ),
        );
      }
    },
  );
}

String getFormattedOpeningHours(Map<String, String> openingHours) {
  if (openingHours.isEmpty) {
    return 'No information available';
  }

  if (openingHours.containsKey('openTime') &&
      openingHours.containsKey('closeTime')) {
    return 'Open: ${openingHours['openTime']} - Close: ${openingHours['closeTime']}';
  } else {
    return 'No information available';
  }
}

