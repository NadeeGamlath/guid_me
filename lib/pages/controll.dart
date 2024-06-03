import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class Controller{
  final String apiKey = 'AIzaSyA51Vw9cExN7qgQzsV4L8uCakY7_z7D6u0';
 // final String apiKey2 = 'oIRxeJxWl7WYJTtQ2FG6n4oH95O2OEsJ';
  final String apiKey2 ='b9a3374e06337729404d5b9494c37924';

  late Uri uri;
  Future<Position> getCurrentPosition() async{
    try{

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy : LocationAccuracy.high,
      );
      return position;
    }catch(e){
      throw Exception('Failed to get current location: $e');
    }
  }
  Future<Map<String , dynamic>> getCurrentLocation(double latitude,double longitude) async{
     uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
    );
    final response = await http.get(uri);
    print(response);

    if(response.statusCode == 200){
      return json.decode(response.body);
    }else{
      throw Exception('Failed to load weather data');
    }
  }
  Future<Map<String,dynamic>> getCurrentWeather(double latitude, double longitude) async{
    print(latitude);
     uri = Uri.parse(
       // 'https://api.tomorrow.io/v4/weather/forecast?location=$latitude,$longitude&apikey=$apiKey2'
         'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey2'
    );
    final response = await http.get(uri);
    print(response.body);
    if (response.statusCode == 200) {

      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
  Future<List<dynamic>> searchNearbyPlaces(String keyword, String type, double radius, double latitude, double longitude) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=$latitude,$longitude' //query strings
        '&radius=$radius'
        '&keyword=$keyword'
        '&type=$type'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['results'];
      } else {
        throw Exception('Failed to fetch nearby places: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch nearby places: ${response.reasonPhrase}');
    }
  }
  Future<double> getPlaceRating(String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=rating'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return double.parse(data['result']['rating'].toString());
      } else {
        throw Exception('Failed to fetch place rating: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch place rating: ${response.reasonPhrase}');
    }
  }
  Future<Map<String, String>> getPlaceOpeningHours(String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=opening_hours'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final openingHours = data['result']['opening_hours'];
        final bool isOpenNow = openingHours['open_now'];
        String openTime = '';
        String closeTime = '';
        if (isOpenNow) {
          openTime = 'Open Now';
        } else {
          openTime = openingHours['periods'][0]['open']['time'];
          closeTime = openingHours['periods'][0]['close']['time'];
        }
        return {'openTime': openTime, 'closeTime': closeTime};
      } else {
        throw Exception('Failed to fetch opening hours: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch opening hours: ${response.reasonPhrase}');
    }
  }
  Future<double> getDistanceToPlace(double latitude, double longitude) async {

    final position = await getCurrentPosition();
    double originLongitude = position.longitude;
    double originLatitude = position.latitude;
    final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=$originLatitude,$originLongitude'
        '&destinations=$latitude,$longitude'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final distance = data['rows'][0]['elements'][0]['distance']['value'];
        return distance / 1000; // Convert distance from meters to kilometers
      } else {
        throw Exception('Failed to fetch distance: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch distance: ${response.reasonPhrase}');
    }
  }
  Future<Map<String, dynamic>?> getCityDescription(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|pageimages&exintro&explaintext&titles=$cityName&pithumbsize=500',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final pageId = pages.keys.first;
        final description = pages[pageId]['extract'];
        final imageUrl = pages[pageId]['thumbnail']?['source']; // Handle null case
        return {'description': description, 'imageUrl': imageUrl};
      } else {
        throw Exception('Failed to load city description');
      }
    } catch (e) {
      print('Error fetching city description: $e');
      return null;
    }
  }
}
