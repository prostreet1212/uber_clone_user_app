import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({Key? key}) : super(key: key);

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentUser =
      FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Trips History',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder(
          stream: completedTripRequestsOfCurrentUser.onValue,
          builder: (BuildContext context, snapshotData) {
            if (snapshotData.hasError) {
              return const Center(
                child: Text(
                  "Error Occurred.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (!(snapshotData.hasData)) {
              return const Center(
                child: Text(
                  "No record found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            Map dataTrips = snapshotData.data!.snapshot.value as Map;
            List<Map<String, dynamic>> tripsList = [];
            dataTrips
                .forEach((key, value) => tripsList.add({"key": key, ...value}));
            return ListView.builder(
                shrinkWrap: true,
                itemCount: tripsList.length,
                itemBuilder: (context, index) {
                  if (tripsList[index]['status'] != null &&
                      tripsList[index]['status'] == 'ended' &&
                      tripsList[index]['userID'] ==
                          FirebaseAuth.instance.currentUser!.uid) {
                    return Card(
                      color: Colors.white12,
                      elevation: 10,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //pickup
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/initial.png',
                                  height: 16,
                                  width: 16,
                                ),
                                SizedBox(
                                  width: 18,
                                ),
                                Expanded(
                                  child: Text(
                                    tripsList[index]['pickUpAddress']
                                        .toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5,),
                                Text(
                                  "\$ " + tripsList[index]["fareAmount"].toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8,),
                            //dropoff
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/final.png',
                                  height: 16,
                                  width: 16,
                                ),
                                SizedBox(
                                  width: 18,
                                ),
                                Expanded(
                                  child: Text(
                                    tripsList[index]['dropOffAddress']
                                        .toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }
                });
          }),
    );
  }
}
