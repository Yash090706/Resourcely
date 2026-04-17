// import "dart:nativewrappers/_internal/vm/lib/async_patch.dart";

// import "dart:async";

import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/PcBookingPage.dart";
import "package:flutter_firebase/FlutterProject/PcroomCoverPage.dart";
import "package:flutter_firebase/FlutterProject/Res_ProfilePage.dart";
import "package:flutter_firebase/FlutterProject/SignInPage.dart";
import "package:flutter_firebase/FlutterProject/my_booking_page.dart";
import "package:flutter_firebase/FlutterProject/profile_page.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "facility_details_page.dart";
import "auth_wrapper.dart";

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool already_booked = false;
  Map<String, Map<String, String>> dateMinMax = {};
  int? pc_number;
  String? min;
  String?max;
  Map<int, Map<String, List<String>>> pc_bookings = {};

  String normalizeDate(Timestamp ts) {
    DateTime dt = ts.toDate();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day
        .toString().padLeft(2, '0')}";
  }

  Future<DateTime> parse_Time(String time) async {
    return DateFormat("h:mm a").parse(time);
  }

  fetch_booking_time() async {
    try {
      pc_bookings.clear();
      min = null;
      max = null;
      pc_bookings[pc_number!] = {};
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
          "PcRoom").where("pcnumber", isEqualTo: pc_number).get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        pc_bookings.putIfAbsent(pc_number!, () => {});
        if (!data.containsKey("date") || !data.containsKey("startTime") ||
            !data.containsKey("endTime")) {
          continue;
        }
        Timestamp date_v = data["date"];

        String dateKey = normalizeDate(date_v);


        // DateTime dt=date_v.toDate();

        // String date=dt.toString();
        String startTime = data["startTime"];
        String endTime = data["endTime"];

        pc_bookings[pc_number]!.putIfAbsent(dateKey, () => []);

        pc_bookings[pc_number]![dateKey]!.add("$startTime,$endTime");

        List<String> slots = pc_bookings[pc_number]![dateKey]!;
        DateTime? minStart;
        DateTime? maxEnd;

        for (String slot in slots) {
          List<String> times = slot.split(",");

          DateTime start = await parse_Time(times[0]);
          DateTime end = await parse_Time(times[1]);

          if (minStart == null || start.isBefore(minStart)) {
            minStart = start;
            min = DateFormat("h:mm a").format(minStart);
          }

          if (maxEnd == null || end.isAfter(maxEnd)) {
            maxEnd = end;
            max = DateFormat("h:mm a").format(maxEnd);
          }
        }
      }
      dateMinMax.clear();

      pc_bookings[pc_number]!.forEach((date, slots) async {
        DateTime? minStart;
        DateTime? maxEnd;

        for (String slot in slots) {
          final times = slot.split(",");

          final start = DateFormat("h:mm a").parse(times[0]);
          final end = DateFormat("h:mm a").parse(times[1]);

          if (minStart == null || start.isBefore(minStart)) {
            minStart = start;
          }
          if (maxEnd == null || end.isAfter(maxEnd)) {
            maxEnd = end;
          }
        }

        dateMinMax[date] = {
          "min": DateFormat("h:mm a").format(minStart!),
          "max": DateFormat("h:mm a").format(maxEnd!),
        };
      });


      setState(() {
        print(pc_bookings);
        print(min);
        print(max);
      });
    }
    catch (err) {
      print(err);
    }
  }

  late StreamSubscription<QuerySnapshot> bookingListener;

  void listenUserBooking() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;

    bookingListener = FirebaseFirestore.instance
        .collection("PcRoom")
        .where("uid", isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      bool shouldBlock = false;

      DateTime now = DateTime.now();
      // DateTime now = DateTime(2026, 2, 28, 10, 02);

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey("date") ||
            !data.containsKey("endTime")) continue;

        DateTime bookingDate =
        (data["date"] as Timestamp).toDate();

        String endTimeString = data["endTime"];

        DateTime parsedEnd =
        DateFormat("hh:mm a").parse(endTimeString);

        DateTime bookingEndDateTime = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
          parsedEnd.hour,
          parsedEnd.minute,
        );

        // 🔥 If booking is still active → block
        if (now.isBefore(bookingEndDateTime)) {
          shouldBlock = true;
          break;
        }
      }

      if (mounted) {
        setState(() {
          already_booked = shouldBlock;
        });
      }
    });
  }

  // void get_blocking() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   bool close = prefs.getBool("close") ?? false;
  //
  //   if (mounted) {
  //     setState(() {
  //       already_booked = close;
  //     });
  //   }
  // }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listenUserBooking();
    // get_blocking();

  }

  @override
  void dispose() {
    bookingListener.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Builder(
            builder: (context) =>
                SafeArea(
                  child: Container(
                    // margin: EdgeInsets.only(top:10),
                    height: 70,
                    color: Color(0xFF00796B),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            showMenu(
                              position: RelativeRect.fromLTRB(0, 0, 0, 0),
                              context: context,
                              items: [
                                PopupMenuItem(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ProfilePage();
                                        },
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        "Profile",
                                        style: TextStyle(
                                          color: Color(0xFF00796B),
                                          fontFamily: "Mono",
                                        ),
                                      ),
                                      SizedBox(width: 3),
                                      Icon(
                                        Icons.account_circle_rounded,
                                        color: Color(0xFF00796B),
                                      )
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: const [
                                      Text(
                                        "Past Booking",
                                        style: TextStyle(
                                          color: Color(0xFF00796B),
                                          fontFamily: "Mono",
                                        ),
                                      ),
                                      SizedBox(width: 9),
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return MyBookingsPage();
                                        },
                                      ),
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: const [
                                      Text(
                                        "Logout",
                                        style: TextStyle(
                                          color: Color(0xFF00796B),
                                          fontFamily: "Mono",
                                        ),
                                      ),
                                      SizedBox(width: 9),
                                      Icon(
                                        Icons.logout,
                                        color: Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Future.delayed(Duration.zero, () async {
                                      await FirebaseAuth.instance.signOut();
                                      await FirebaseAuth.instance.signOut();

                                      final prefs =
                                      await SharedPreferences.getInstance();
                                      await prefs.clear();

                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const AuthWrapper(),
                                        ),
                                            (route) => false,
                                      );
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        Expanded(
                          child: Container(
                            height: 70,
                            child: TabBar(
                              indicatorColor: Color(0xFFB2DFDB),
                              indicatorWeight: 5,

                              tabs: [
                                Tab(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      children: [
                                        Text(
                                          "Pc Room",
                                          style: TextStyle(
                                            fontFamily: "Mono",
                                            fontSize: 25,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.computer_outlined,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      children: [
                                        Text(
                                          "Turf",
                                          style: TextStyle(
                                            fontFamily: "Mono",
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.sports_cricket,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Wrap(
                                      direction: Axis.horizontal,
                                      children: [
                                        Text(
                                          "Badminton",
                                          style: TextStyle(
                                            fontFamily: "Mono",
                                            fontSize: 25,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.sports_tennis_outlined,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin:
                        EdgeInsets.only(top: 30, left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: MediaQuery
                            .of(context)
                            .size
                            .width - 20,
                        height: 200,
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 150,
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: Image.asset(
                                  "Assets/Images/pcroomcover.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Pc Room",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: "Mono",
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    // ALL your cards remain same
                    Center(
                      child: Card(
                        elevation: 6,
                        shadowColor: Colors.black87,
                        color: Colors.grey.shade200,
                        margin: EdgeInsets.only(
                            left: 10, right: 10, top: 20),
                        child: ListTile(
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF00796B),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Mono",
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            " -Well Maintained Pc Room for Clg Students.\n Available in College Hours.",
                            style: TextStyle(
                              fontFamily: "Mono",
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
    Center( child: Card( elevation: 6, shadowColor: Colors.black87, color: Colors.grey.shade200,
      margin: EdgeInsets.only(left:10,right: 10,top:20), child: ListTile(title:
      Row( mainAxisSize: MainAxisSize.min, children: const [ Icon( Icons.rule, color: Color(0xFF00796B), size: 18, ),
        SizedBox(width: 6), Text( "Rules & Guidelines", style: TextStyle( fontWeight: FontWeight.w700, fontFamily: "Mono", fontSize: 15, color: Colors.black, ), ), ], ), subtitle: Text(" -Only College Students Allowed \n -Max booking:2Hrs\n -Min booking:30Min\n -Per day Only single Booking Allowed",style: TextStyle(fontFamily: "Mono",fontSize: 12,color: Colors.black)), ), ), ), Center( child: Card( elevation: 6, shadowColor: Colors.black87, color: Colors.grey.shade200, margin: EdgeInsets.only(left:10,right: 10,top:20), child: ListTile(
    title: Row( mainAxisSize: MainAxisSize.min, children: const [
      Icon( Icons.timer, color: Color(0xFF00796B), size: 18, ), SizedBox(width: 6), Text( "Operating Hours", style: TextStyle( fontWeight: FontWeight.w700, fontFamily: "Mono", fontSize: 15, color: Colors.black, ), ), ], ), subtitle: Text(" -7.30 to 5.30",style: TextStyle(fontFamily: "Mono",fontSize: 12,color: Colors.black)), ), ), ),


                    // keep remaining cards EXACTLY SAME

                    SizedBox(height: 20),

                    SizedBox(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width - 20,
                      child: already_booked
                          ? ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                          WidgetStatePropertyAll(
                              Colors.redAccent),
                          padding: WidgetStatePropertyAll(
                              EdgeInsets.all(20)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return Homepage();
                              },
                            ),
                          );
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                "Cant Proceed To Book Now...Only single Booking allowed per day.",
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
                                  fontFamily: "Mono",
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              backgroundColor:
                              Colors.redAccent,
                              behavior: SnackBarBehavior
                                  .floating,
                            ),
                          );
                        },
                        child: Text(
                          "Booking Temporarily Closed",
                          style: TextStyle(
                            fontFamily: "Mono",
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                          WidgetStatePropertyAll(
                            Color(0xFF00796B),
                          ),
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.all(20),
                          ),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)))
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return Pcroomcoverpage();
                              },
                            ),
                          );
                        },
                        child: Text(
                          "Proceed to Book->",
                          style: TextStyle(
                            fontFamily: "Mono",
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20)
                  ],
                ),
              ),
            ),
            const FacilityDetailsPage(facilityId: "turf"),
            const FacilityDetailsPage(facilityId: "badminton")
          ],
        ),
      ),
    );
  }
}