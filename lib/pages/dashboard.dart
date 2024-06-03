import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:getwidget/components/floating_widget/gf_floating_widget.dart';
import 'package:getwidget/components/list_tile/gf_list_tile.dart';
import 'package:getwidget/getwidget.dart';
import 'package:guid_me/pages/result-view.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'controll.dart';
import 'db-controller.dart';
import 'description.dart';


class Dashboard extends StatefulWidget{
  final String storedValue;
  const Dashboard({Key? key, required this.storedValue}) : super(key: key);
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Object wholeLocationData = {};
  late String locationName = "";
  late String userName = '';
  late double temperature = 0.0;
  late Controller controller = Controller();
  late List<Widget> tagButtonsList = [];
  late List<String> tagNames = [];
  List<Map<String, dynamic>> userData = [];

  void initState(){
    super.initState();
    updateName();
    fetchWeatherData();
    fetchTagNames();
  }

  @override

  Future<void> fetchWeatherData() async {
    final PermissionStatus status = await Permission.location.request();

    if (status.isGranted){ //if allowed
      try {
        //Get longitute and latitude
        final position = await controller.getCurrentPosition();
        // Get current location using position value
        final locationData = await controller.getCurrentLocation(
            position.latitude, position.longitude);
        wholeLocationData = locationData;
        //Get temp
        print(locationData);
        final temp = await controller.getCurrentWeather(
            position.latitude, position.longitude);
        //Accessing location data result
        final List<dynamic> results =  locationData['results'];
        //filter temp
        final tempData = temp['main']['feels_like'];
        print(tempData);
        if(results.isNotEmpty){
          final plusCode = locationData['plus_code']['compound_code'];
          final locationNameParts = plusCode.split(' '); //split by the space
          print('*****************************************************************************************************');
          print(locationNameParts);
          print('*****************************************************************************************************');

          if(locationNameParts.length >= 2){
            //variable eka refer karan hamathanama eka para update wenawa
           setState(() {
             locationName = locationNameParts.sublist(1).join(' ');
             print('****************************************###');
             print(locationName);
             print('*****************************************************************************************************');
             temperature = tempData != null ? tempData.toDouble() : 0.0;
            });
          }else{
            setState(() {
              locationName = plusCode;
              temperature = 0.0;
            });
          }
          temperature = (tempData  - 273.15);
        }else{
          print("No results found");
        }
      } catch (e) {
        print('Failed to fetch weather data: $e');
      }
    }else{
      print('LOcation permission denied');
    }

    }
  List<Widget> _generateTagButtons() {
    List<Widget> tagButtons = [];
    print("###########################################3");
    print(tagNames);
    print("###########################################3");

    for (String tagName in tagNames) {
      tagButtons.add(
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: GFButton(
              onLongPress: () => _deleteTag(tagName),
              onPressed: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=> ResultView(
                      buttonText: tagName, // Use tagName as buttonText
                      keyword: tagName.toLowerCase(), // Use tagName as keyword in lowercase
                      type: tagName.toLowerCase(),
                    )
                    )
                );
              },
              text: tagName, // Set the button text to tagName
              size: GFSize.SMALL,
              color: hexColor("62A1AA"),
            ),
          )
      );
    }
    return tagButtons;
    // setState(() {
    //   tagButtonsList = tagButtons;
    //   print("TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTtttt");
    //   print(tagButtons);
    //   print("TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTtttt");
    //
    // });
  }
  Future<void> _deleteTag(String tagName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Tag'),
          content: Text('Are you sure you want to delete the tag "$tagName"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await DatabaseController.instance.deleteTagName(tagName);
                Navigator.of(context).pop();
                fetchTagNames(); // Refresh the tag buttons
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> fetchTagNames() async {
    try {
      List<Map<String, dynamic>> tags = await DatabaseController.instance.getData('tag_names');
      setState(() {
        tagNames = tags.map((tag) => tag['name'].toString()).toList();
        tagButtonsList = _generateTagButtons();
        print("################################################################");
        print(tagNames);
        print("################################################################");

      });
    } catch (e) {
      print('Failed to fetch tag names: $e');
    }
  }
  void _showAddPopup(){
    TextEditingController textController = TextEditingController();
    fetchTagNames();
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
              title: Text('Add New Item'),
              content: TextField(
                controller: textController,
                decoration: InputDecoration(hintText: 'Enter item name'),
              ),
              actions: <Widget>[
                TextButton(child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),TextButton(onPressed:() async {
                  String newItem = textController.text;
                  await DatabaseController.instance.insertTagName(newItem);
                  print('Saved: $newItem');
                  print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1111111111111111");
                  Navigator.of(context).pop();
                  _generateTagButtons();
                  fetchTagNames();
                }, child: Text('Save'))
              ]

          );
        }
    );
  }
  Future<void> _deleteAllTags() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Tags'),
          content: Text('Are you sure you want to delete all tags?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete All'),
              onPressed: () async {
                await DatabaseController.instance.deleteAllTagNames();
                Navigator.of(context).pop();
                fetchTagNames(); // Refresh the tag buttons
              },
            ),
          ],
        );
      },
    );
  }
  Future<void>updateName()async{
    try{
      List<Map<String, dynamic>> result = await DatabaseController.instance.getData('user_data');
      setState(() {
        userName = result[0]['name'];
      });
    } catch(e){
      print('Failed to fetch user data: $e');
    }
  }
  // Future<void> fetchUserData() async {
  //   try {
  //     List<Map<String, dynamic>> result = await DatabaseController.instance.getData('user_data');
  //     setState(() {
  //       userData = result;
  //       print('###################^^^^^^^^^^');
  //       print(userData);
  //       print('###################^^^^^^^^^^');
  //     });
  //   } catch (e) {
  //     print('Failed to fetch user data: $e');
  //   }
  // }
  void _showEditPopup(Map<String, dynamic> data) {
    TextEditingController nameController = TextEditingController(text: data['name']);
    TextEditingController valueController = TextEditingController(text: data['value']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),

            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                updateName();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                await DatabaseController.instance.updateUserData(
                  data['id'],
                  nameController.text,
                  valueController.text,
                );
                Navigator.of(context).pop();
               // fetchUserData(); // Refresh the data
                updateName();
              },
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return  Scaffold(
       //backgroundColor: Colors.greenAccent,
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/bg.jpeg'), // Adjust the path based on your project structure
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.8), // Adjust the opacity as needed
                BlendMode.srcOver,
              ),
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: hexColor("62A1AA"),
                ),
                child: Row(
                  children: [
                    Text(
                      'GuideMe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 40,
                    ),
                    // SizedBox(width: 10), // Add some space between the icon and text
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () async {
                  // Navigator.pop(context); // Close the drawer
                  List<Map<String, dynamic>> result = await DatabaseController.instance.getData('user_data');
                  for (var data in result) {
                    _showEditPopup(data);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Clear Settings'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _deleteAllTags();
                  // Navigate to settings page
                },
              ),
              // Other list tile items...
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 450.0, bottom: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 16.0),
                    Text(
                      'rashmigamlath2001@gmail.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background Image
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4), // Adjust the opacity value here
                BlendMode.srcOver,
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  'images/bg.jpeg', // Replace with the actual path to your image
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              color: Colors.white.withOpacity(0.7), // Adjust the opacity as needed
            ),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer(); // Use Scaffold.of(context) inside Builder
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          'Hi, $userName!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: 20),
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: 180,
                      width: 500,
                      // child: Center(

                      child: GFCard(
                        padding: EdgeInsets.zero,
                        boxFit: BoxFit.cover,
                        // color: hexColor("F9F7F6"),
                        color: Colors.white70,
                        title:  GFListTile(
                          // avatar: GFAvatar(),
                          title: Text(
                            locationName.isNotEmpty ? locationName : 'Loading...',
                            style: TextStyle(
                                fontSize: 27
                            ),
                          ),
                          subTitle: Text(
                            temperature != 0.0 ? '${temperature.toStringAsFixed(2)}°C' : 'Loading...',
                            style: TextStyle(
                              fontSize: 25, // Adjust the font size as needed
                            ),
                          ),
                        ),
                      ),
                      // ),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        GFButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Description(
                                locationName: wholeLocationData, // Pass the location name to the new page
                              )),
                            );
                          },
                          text: "Read more about",
                          size: GFSize.SMALL,
                          // icon: const Icon(Icons.home),
                          color: hexColor("62A1AA"),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: SizedBox(
                            child: Text(
                              'Quick Guides',
                              style: TextStyle(
                                  fontSize: 30
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 300,
                          child: GridView.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10.0,
                            childAspectRatio: 3,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GFButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResultView(
                                        buttonText: "Hotels",
                                        keyword: "hotel",
                                        type: "hotel",
                                      )),
                                    );
                                  },
                                  text: "Hotels",
                                  size: GFSize.SMALL,
                                  // icon: const Icon(Icons.home),
                                  color: hexColor("62A1AA"),
                                ),
                              ),Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GFButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResultView(
                                        buttonText: "Park",
                                        keyword: "park",
                                        type: "park",
                                      )),
                                    );
                                  },
                                  text: "Parks",
                                  size: GFSize.SMALL,
                                  // icon: const Icon(Icons.home),
                                  color: hexColor("62A1AA"),
                                ),
                              ),Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GFButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResultView(
                                        buttonText: "Gym",
                                        keyword: "gym",
                                        type: "gym",
                                      )),
                                    );
                                  },
                                  text: "Gym",
                                  size: GFSize.SMALL,
                                  // icon: const Icon(Icons.home),
                                  color: hexColor("62A1AA"),
                                ),
                              ),Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GFButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResultView(
                                        buttonText: "Cafe",
                                        keyword: "cafe",
                                        type: "cafe",
                                      )),
                                    );
                                  },
                                  text: "Cafes",
                                  size: GFSize.SMALL,
                                  // icon: const Icon(Icons.home),
                                  color: hexColor("62A1AA"),
                                ),
                              ),Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GFButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResultView(
                                        buttonText: "Bus station",
                                        keyword: "bus_station",
                                        type: "bus_station",
                                      )),
                                    );
                                  },
                                  text: "Bus Station",
                                  size: GFSize.SMALL,
                                  // icon: const Icon(Icons.home),
                                  color: hexColor("62A1AA"),
                                ),
                              ),Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GFButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResultView(
                                        buttonText: "Train station",
                                        keyword: "train_station",
                                        type: "train_station",
                                      )),
                                    );
                                  },
                                  text: "Train Stations",
                                  size: GFSize.SMALL,
                                  // icon: const Icon(Icons.home),
                                  color: hexColor("62A1AA"),
                                ),
                              ),
                              ...tagButtonsList
                            ],
                          ),
                        ),

                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GFFloatingWidget(
        child: GFButton(
          onPressed: _showAddPopup,
          text: "Add a Keyword",
          size: GFSize.SMALL,
          // icon: const Icon(Icons.add),
          color: hexColor("62A1AA"),
          shape: GFButtonShape.pills,
        ),
        verticalPosition: MediaQuery.of(context).size.height * 0.9,
        horizontalPosition: MediaQuery.of(context).size.width * 0.4,
      ),
    );
  }
  hexColor(String hexColor) {
    final hexCode = hexColor.replaceAll("#", "");
    return Color(int.parse("FF$hexCode", radix: 16));
  }
}
