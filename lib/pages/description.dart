import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'controll.dart';

class Description extends StatefulWidget {
  final Object locationName;
  const Description({Key? key, required this.locationName}) : super(key: key);

  @override
  _DescriptionState createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  String? nearestCity;
  late String description = "";
  late String imageUrl = "";
  bool isLoading = true; // Track loading state
  Map<String, dynamic>? cityDescription;
  Color customColor = Color(0xFF62A1AA);

  @override
  void initState() {
    super.initState();
    findNearestCity();
  }
   void findNearestCity() async {
     // Convert locationName to a map
     Map<String, dynamic> location = widget.locationName as Map<String, dynamic>;
     // Extract data from the results list
     List<dynamic> results = location['results'] as List<dynamic>;

     // Create a list to store cities
     List<String> cities = [];

     // Iterate through each result
     for (var result in results) {
       // Extract address_components from the result
       List<dynamic> addressComponents = result['address_components'] as List<dynamic>;

       // Iterate through each address component
       for (var addressComponent in addressComponents) {
         // Check if the address component contains types key with value locality
         if (addressComponent.containsKey('types') &&
             addressComponent['types'].contains('locality')) {
           // Extract long_name as a city
           String city = addressComponent['long_name'] as String;
           cities.add(city);
         }
       }
     }

     // Find the nearest city (you can implement your logic here)
     if (cities.isNotEmpty) {
       // nearestCity = cities.first; // Assuming the first city is the nearest
       nearestCity = "Kandy"; // Assuming the first city is the nearest
       Controller controller =  Controller ();
       // Call getCityDescription and pass nearestCity as input
       Map<String, dynamic>? cityDescription = await controller.getCityDescription(nearestCity!);
       if (cityDescription != null) {
         // Handle city description data

         description = cityDescription['description'];
         imageUrl = cityDescription['imageUrl'] ?? ''; // Handle null imageUrl
         print('City Description: $description');
         print('Image URL: $imageUrl');
         setState(() {
           cityDescription = cityDescription;
           isLoading = false;
         });
       } else {
         print('City description not available.');
       }
       setState(() {}); // Update the UI
     }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: customColor,
        title: Text('More About Location'),
      ),
      body: Center(
        child: isLoading ?  CircularProgressIndicator() :
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text(
            //   'Location Name:',
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            // ),
            SizedBox(height: 10),
            // if (nearestCity != null)
            Column(
                children: [
                  // Text(
                  //   'City Description:',
                  //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  // ),
                  SizedBox(height: 5),
                  Image.network(
                    imageUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 20), // Adjust padding as needed
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ]
            )
          ],
        ),

      ),
    );
  }
}
