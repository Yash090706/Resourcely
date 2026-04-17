// // import "dart:io";
//
// import "dart:convert";
//
// import "package:cloud_firestore/cloud_firestore.dart";
// import "package:flutter/material.dart";
// import "package:intl/intl.dart";
// import "package:shared_preferences/shared_preferences.dart";
//
// import "PcBookingPage.dart";
// //
// class Pcroomcoverpage extends StatefulWidget {
//   const Pcroomcoverpage({super.key});
//
//   @override
//   State<Pcroomcoverpage> createState() => _PcroomcoverpageState();
// }
//
// class _PcroomcoverpageState extends State<Pcroomcoverpage> {
//   Map<String, Map<String, String>> dateMinMax = {};
//   int? pc_number;
//   String? min;
//   String?max;
//   Map<int,Map<String,List<String>>> pc_bookings={};
//   String normalizeDate(Timestamp ts) {
//     DateTime dt = ts.toDate();
//     return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
//   }
//   Future<DateTime> parse_Time(String time) async {
//     return DateFormat("h:mm a").parse(time);
//   }
//
//   fetch_booking_time()async{
//     try{
//       pc_bookings.clear();
//       min = null;
//       max = null;
//       pc_bookings[pc_number!] = {};
//       QuerySnapshot snapshot=await FirebaseFirestore.instance.collection("PcRoom").where("pcnumber",isEqualTo: pc_number).get();
//       for(var doc in snapshot.docs){
//         final data=doc.data() as Map<String,dynamic>;
//         pc_bookings.putIfAbsent(pc_number!,()=>{});
//         if(!data.containsKey("date") || !data.containsKey("startTime") || !data.containsKey("endTime")){
//           continue;
//         }
//         Timestamp date_v=data["date"];
//
//         String dateKey = normalizeDate(date_v);
//
//
//         // DateTime dt=date_v.toDate();
//
//         // String date=dt.toString();
//         String startTime=data["startTime"];
//         String endTime=data["endTime"];
//
//         pc_bookings[pc_number]!.putIfAbsent(dateKey,() =>[]);
//
//         pc_bookings[pc_number]![dateKey]!.add("$startTime,$endTime");
//
//         List<String> slots=pc_bookings[pc_number]![dateKey]!;
//         DateTime? minStart;
//         DateTime? maxEnd;
//
//         for (String slot in slots){
//           List<String> times = slot.split(",");
//
//           DateTime start = await parse_Time(times[0]);
//           DateTime end   = await parse_Time(times[1]);
//
//           if (minStart == null || start.isBefore(minStart)) {
//             minStart = start;
//             min=DateFormat("h:mm a").format(minStart);
//           }
//
//           if (maxEnd == null || end.isAfter(maxEnd)) {
//             maxEnd = end;
//             max=DateFormat("h:mm a").format(maxEnd) ;
//           }
//         }
//
//       }
//       dateMinMax.clear();
//
//       pc_bookings[pc_number]!.forEach((date, slots) async {
//         DateTime? minStart;
//         DateTime? maxEnd;
//
//         for (String slot in slots) {
//           final times = slot.split(",");
//
//           final start = DateFormat("h:mm a").parse(times[0]);
//           final end   = DateFormat("h:mm a").parse(times[1]);
//
//           if (minStart == null || start.isBefore(minStart)) {
//             minStart = start;
//           }
//           if (maxEnd == null || end.isAfter(maxEnd)) {
//             maxEnd = end;
//           }
//         }
//
//         dateMinMax[date] = {
//           "min": DateFormat("h:mm a").format(minStart!),
//           "max": DateFormat("h:mm a").format(maxEnd!),
//         };
//       });
//
//
//       setState(() {
//         print(pc_bookings);
//         print(min);
//         print(max);
//
//       });
//     }
//     catch(err){
//       print(err);
//
//     }
//   }
//   void getPcBlocking() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     String? jsonData = prefs.getString("pc-blocking");
//
//     if (jsonData != null) {
//       Map<String, dynamic> data = jsonDecode(jsonData);
//       print(data);
//       // print(data["date"]);
//       // print(data["pcnumber"]);
//       // print(data["reason"]);
//     }
//   }
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     getPcBlocking();
//
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Resourcely",
//           style: TextStyle(
//             fontSize: 20,
//             fontFamily: "Mono",
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         backgroundColor: const Color(0xFF00796B),
//         foregroundColor: Colors.white,
//       ),
//       body: Container(
//           margin: EdgeInsets.only(top:2),
//           padding: EdgeInsetsGeometry.all(30),
//           child:GridView.builder(itemCount:4,scrollDirection:Axis.vertical,gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//               maxCrossAxisExtent: 300,crossAxisSpacing:20,mainAxisSpacing:25,mainAxisExtent:238),
//               itemBuilder:(context,index){return Card(
//                   child: Column(
//                     children: [Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Image.network("https://tse2.mm.bing.net/th/id/OIP.uUwuVyEOr4oYpzjFO9kU2wHaFj?pid=Api&P=0&h=220"),
//                     ),
//                       // SizedBox(child: CircleAvatar(child: Text("${index+1}"),),),
//                       SizedBox(
//                         width: 160,
//                         child: TextButton(style:ButtonStyle(
//                             backgroundColor: WidgetStatePropertyAll(Color(0xFF007968)),
//                             padding: WidgetStatePropertyAll(EdgeInsetsGeometry.all(10))
//                         ),onPressed: ()async{
//                           pc_number=index+1;
//                           print("Pc ${pc_number}");
//                           await fetch_booking_time();
//                           Navigator.push(context, MaterialPageRoute(builder: (context){
//                             return Pcbookingpage(pcnumber: index+1, minBookedTime: min,
//                                 maxBookedTime: max,bookingsByDate: pc_bookings[pc_number]!);
//                           }));
//                         }, child: Text("Book PC ${index+1}",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w700,color:Colors.white),)),
//                       ),SizedBox(height: 3,),
//                       SizedBox(
//                         width: 160,
//                         child: TextButton(style:ButtonStyle(
//                             backgroundColor: WidgetStatePropertyAll(Colors.grey.shade400),
//                             padding: WidgetStatePropertyAll(EdgeInsetsGeometry.all(10))
//                         ),onPressed: () async {
//                           pc_number = index + 1;
//                           await fetch_booking_time();
//
//                           if (pc_bookings[pc_number] == null ||
//                               pc_bookings[pc_number]!.isEmpty ||
//                               min == null ||
//                               max == null) {
//                             // No data → show message instead of crashing
//                             showDialog(
//                               context: context,
//                               builder: (_) => AlertDialog(
//                                 title: const Text("All Slots Available",style: TextStyle(color: Colors.green),),
//                                 content: const Text("Still No booking done for this PC.",style: TextStyle(color: Colors.black)),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text("OK"),
//                                   )
//                                 ],
//                               ),
//                             );
//                             return;
//                           }
//
//                           showDialog(
//                             context: context,
//                             builder: (context) {
//                               return AlertDialog(
//                                 title: const Text("Booked Slots"),
//                                 content: SizedBox(
//                                   width: 400, // control width here
//                                   child: SingleChildScrollView(
//                                     child: Column(
//                                       children: [
//                                         // Header Row
//                                         Row(
//                                           children: const [
//                                             Expanded(
//                                               flex: 3,
//                                               child: Text("Date",
//                                                   style: TextStyle(fontWeight: FontWeight.bold)),
//                                             ),
//                                             Expanded(
//                                               flex: 4,
//                                               child: Text("Time",
//                                                   style: TextStyle(fontWeight: FontWeight.bold)),
//                                             ),
//                                             Expanded(
//                                               flex: 2,
//                                               child: Text("Status",
//                                                   style: TextStyle(fontWeight: FontWeight.bold)),
//                                             ),
//                                           ],
//                                         ),
//                                         const Divider(),
//
//                                         // Data Rows
//                                         ...dateMinMax.entries.map((entry) {
//                                           final date = entry.key;
//                                           final minT = entry.value["min"];
//                                           final maxT = entry.value["max"];
//
//                                           return Padding(
//                                             padding: const EdgeInsets.symmetric(vertical: 6),
//                                             child: Row(
//                                               children: [
//                                                 Expanded(
//                                                   flex: 3,
//                                                   child: Text(date),
//                                                 ),
//                                                 Expanded(
//                                                   flex: 4,
//                                                   child: Text("$minT - $maxT"),
//                                                 ),
//                                                 SizedBox(width: 5,),
//                                                 const Expanded(
//                                                   flex: 2,
//                                                   child: Text(
//                                                     "Booked",
//                                                     style: TextStyle(color: Colors.red),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         }).toList(),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text("Close"),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         }
//                             , child: Text("View Slot",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w700,color:Colors.grey.shade800),)),
//                       ),
//                       SizedBox(height: 3,)
//                     ],
//                   )
//               );})
//       ),
//     );
//   }
// }
import "dart:convert";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "PcBookingPage.dart";

class Pcroomcoverpage extends StatefulWidget {
  const Pcroomcoverpage({super.key});

  @override
  State<Pcroomcoverpage> createState() => _PcroomcoverpageState();
}

class _PcroomcoverpageState extends State<Pcroomcoverpage> {

  /// ✅ Changed: Now stores list of slots per date
  Map<String, List<String>> dateMinMax = {};

  int? pc_number;
  Map<int, Map<String, List<String>>> pc_bookings = {};

  String normalizeDate(Timestamp ts) {
    DateTime dt = ts.toDate();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetch_booking_time() async {
    try {

      pc_bookings.clear();
      dateMinMax.clear();

      pc_bookings[pc_number!] = {};

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("PcRoom")
          .where("pcnumber", isEqualTo: pc_number)
          .get();

      for (var doc in snapshot.docs) {

        final data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey("date") ||
            !data.containsKey("startTime") ||
            !data.containsKey("endTime")) {
          continue;
        }

        Timestamp date_v = data["date"];
        String dateKey = normalizeDate(date_v);

        String startTime = data["startTime"];
        String endTime = data["endTime"];

        pc_bookings[pc_number]!
            .putIfAbsent(dateKey, () => []);

        /// Store real slots
        pc_bookings[pc_number]![dateKey]!
            .add("$startTime,$endTime");
      }

      /// ✅ FIX: Do NOT calculate min-max
      /// Just store actual slots
      pc_bookings[pc_number]!.forEach((date, slots) {
        dateMinMax[date] = List.from(slots);
      });

      setState(() {});

    } catch (err) {
      print(err);
    }
  }

  void getPcBlocking() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString("pc-blocking");

    if (jsonData != null) {
      Map<String, dynamic> data = jsonDecode(jsonData);
      print(data);
    }
  }

  @override
  void initState() {
    super.initState();
    getPcBlocking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Resourcely",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "Mono",
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
    child: Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.all(30),
    child: Column(
    children: List.generate(4, (index) {
    return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    child: Card(
    child: Column(
    children: [
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: SizedBox(
    width: double.infinity,
    height: 180,
    child: Image.network(
    "https://tse2.mm.bing.net/th/id/OIP.uUwuVyEOr4oYpzjFO9kU2wHaFj?pid=Api&P=0&h=220",
    fit: BoxFit.cover,
    ),
    ),
    ),

    /// BOOK BUTTON
    Padding(
      padding: const EdgeInsets.only(left:8,right: 8),
      child: SizedBox(
      width: double.infinity,
      child: TextButton(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
      backgroundColor: const WidgetStatePropertyAll(
      Color(0xFF007968),
      ),
      padding: const WidgetStatePropertyAll(
      EdgeInsets.all(10),
      ),
      ),
      onPressed: () async {
      pc_number = index + 1;

      await fetch_booking_time();

      Navigator.push(
      context,
      MaterialPageRoute(
      builder: (context) {
      return Pcbookingpage(
      pcnumber: index + 1,
      bookingsByDate:
      pc_bookings[pc_number] ?? {},
      );
      },
      ),
      );
      },
      child: Text(
      "Book PC ${index + 1}",
      style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      ),
      ),
      ),
      ),
    ),

    const SizedBox(height: 3),

    /// VIEW SLOT BUTTON
    Padding(
      padding: const EdgeInsets.only(left:8,right: 8),
      child: SizedBox(
      width: double.infinity,
      child: TextButton(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
      backgroundColor:
      WidgetStatePropertyAll(
      Colors.grey.shade400,
      ),
      padding: const WidgetStatePropertyAll(
      EdgeInsets.all(10),
      ),
      ),
      onPressed: () async {
      pc_number = index + 1;
      await fetch_booking_time();

      if (dateMinMax.isEmpty) {
      showDialog(
      context: context,
      builder: (_) => AlertDialog(
      title: const Text(
      "All Slots Available",
      style: TextStyle(
      color: Colors.green,
      ),
      ),
      content: const Text(
      "Still No booking done for this PC.",
      ),
      actions: [
      TextButton(
      onPressed: () =>
      Navigator.pop(context),
      child: const Text("OK"),
      )
      ],
      ),
      );
      return;
      }

      showDialog(
      context: context,
      builder: (context) {
      return AlertDialog(
      title: const Text("Booked Slots"),
      content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
      child: Column(
      children: [
      Row(
      children: const [
      Expanded(
      flex: 3,
      child: Text(
      "Date",
      style: TextStyle(
      fontWeight:
      FontWeight.bold,
      ),
      ),
      ),
      Expanded(
      flex: 5,
      child: Text(
      "Time",
      style: TextStyle(
      fontWeight:
      FontWeight.bold,
      ),
      ),
      ),
      ],
      ),
      const Divider(),

      ...dateMinMax.entries.map(
      (entry) {
      final date = entry.key;
      final slots =
      entry.value;

      return Padding(
      padding:
      const EdgeInsets
          .symmetric(
      vertical: 6,
      ),
      child: Row(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
      Expanded(
      flex: 3,
      child:
      Text(date),
      ),
      Expanded(
      flex: 5,
      child:
      Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: slots
          .map(
      (slot) {
      final times =
      slot.split(
      ",");
      return Text(
      "${times[0]} - ${times[1]}",
      );
      }).toList(),
      ),
      ),
      ],
      ),
      );
      },
      ).toList(),
      ],
      ),
      ),
      ),
      actions: [
      TextButton(
      onPressed: () =>
      Navigator.pop(
      context),
      child:
      const Text("Close"),
      ),
      ],
      );
      },
      );
      },
      child: Text(
      "View Slot",
      style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade800,
      ),
      ),
      ),
      ),
    ),

    const SizedBox(height: 10),
    ],
    ),
    ),
    );
    }),
    ),
    ),
    ),
    );
  }
}
