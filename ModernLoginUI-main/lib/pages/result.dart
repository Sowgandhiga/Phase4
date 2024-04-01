import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:modernlogintute/pages/boxes.dart';
import 'package:modernlogintute/pages/homepage.dart';
import 'package:modernlogintute/pages/output.dart';

class Result extends StatefulWidget {
  const Result({Key? key}) : super(key: key);

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  int? selectedIndex;
  List<dynamic> locdata = [];
  var cabName, bgimg;
  bool showData = false;

  Future<Map<String, dynamic>> fetchData(pickup, dropoff) async {
    var apiUrl = 'https://cabcompare.pythonanywhere.com/cab/$pickup/$dropoff';

    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Request was successful
        var jsonResponse = json.decode(response.body);
        var cabName = jsonResponse[0];
        var cabDetails = jsonResponse[1];
        var bgimg = "Not Found";
        if (cabName != null && cabName.isNotEmpty) {
          if (cabName == "Uber") {
            bgimg = "lib/images/Uber.jpg";
          } else if (cabName == "Ola") {
            bgimg = "lib/images/Ola.jpg";
          } else {
            bgimg = "lib/images/Rapido.jpg";
          }
        }
        List<String> cabDetailsList = [];
        for (var detail in cabDetails) {
          cabDetailsList.add(detail.toString());
        }
        return {
          'cabName': cabName,
          'bgimg': bgimg,
          'cabDetails': cabDetailsList
        };
      } else {
        // Request failed with error status code
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      // An error occurred during the request
      throw Exception('Failed to load data: $e');
    }
  }

  List<Widget> _buildLocDataSubtitle() {
    List<Widget> subtitleWidgets = [];
    for (var data in locdata) {
      subtitleWidgets.add(Text(
        data,
        style: TextStyle(
          fontFamily: "Times New Roman",
          fontSize: 14,
        ),
      ));
    }
    return subtitleWidgets;
  }

  void logoutUser() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: logoutUser, icon: Icon(Icons.logout))],
      ),
      backgroundColor: const Color.fromARGB(255, 60, 20, 74),
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: boxLocation.length,
                        itemBuilder: (context, index) {
                          Output output = boxLocation.getAt(index);
                          return ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pickup: ${output.pickup}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Drop: ${output.drop}',
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // When a ListTile is tapped, store the index in a variable
                              setState(() {
                                selectedIndex = index;
                                showData =
                                    false; // Reset showData when a new item is selected
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: selectedIndex != null
                      ? () async {
                          // Store selectedIndex in a local variable
                          int index = selectedIndex!;
                          Output output = boxLocation.getAt(index);
                          var pickup = output.pickup;
                          var drop = output.drop;

                          try {
                            // Fetch data from the API
                            var response = await fetchData(pickup, drop);
                            print(response['cabName']);
                            print(response['bgimg']);
                            print(response['cabDetails']);
                            cabName = response['cabName'];
                            bgimg = response['bgimg'];

                            setState(() {
                              locdata.clear(); // Clear previous data
                              for (var i in response['cabDetails']) {
                                locdata.add(i.toString());
                              }
                              showData = true; // Show data after fetching
                            });
                          } catch (e) {
                            // Handle errors during data fetching
                            print('Error fetching data: $e');
                          }
                        }
                      : null, // Disable button if no index is selected
                  child: Text(showData ? "" : "Show"),
                ),
              ),
              if (showData)
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: locdata.isNotEmpty
                              ? CircleAvatar(backgroundImage: AssetImage(bgimg))
                              : null,
                          title: Text(
                            cabName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLocDataSubtitle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      boxLocation.clear();
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Home Page'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
