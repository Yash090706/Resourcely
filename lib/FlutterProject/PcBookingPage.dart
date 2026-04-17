import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/FlutterProject/HomePage.dart';
import 'package:flutter_firebase/FlutterProject/SignInPage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pcbookingpage extends StatefulWidget {

  int pcnumber;
  final String? minBookedTime;
  final String? maxBookedTime;
  final Map<String, List<String>> bookingsByDate;

  Pcbookingpage({required this.pcnumber,this.minBookedTime,
    this.maxBookedTime, required this.bookingsByDate,});

  @override
  State<Pcbookingpage> createState() => _PcbookingpageState();
}

class _PcbookingpageState extends State<Pcbookingpage> {
  int _timeStringToMinutes(String time) {
    final dt = DateFormat("h:mm a").parse(time);
    return dt.hour * 60 + dt.minute;
  }
  int? bookedStartMin;
  int? bookedEndMin;
  bool loading=false;

  String otp_email="";
  int membersCount = 1;
  final TextEditingController mcount = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  String? timeError;
  String? dateError;
  bool hasError = false;

  List<TextEditingController> mname = [];
  List<TextEditingController> mid = [];
  List<TextEditingController> mdept = [];

  List<String?> mname_err = [];
  List<String?> mid_err = [];
  List<String?> mdept_err = [];
  List<String?> msid_err = [];

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('hh:mm a').format(dt);
  }

  List<Map<String, dynamic>> membersInfo = [];

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool get _isToday {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    return selectedDate!.year == now.year &&
        selectedDate!.month == now.month &&
        selectedDate!.day == now.day;
  }

  bool get _isAfterBookingHours {
    return _toMinutes(TimeOfDay.now()) > (16 * 60 + 30);
  }

  String? validateTime({
    required TimeOfDay picked,
    required bool isStart,
  }) {
    final startMaxLimit = 16 * 60 + 30;
    final endMinLimit = 8 * 60 + 30;
    final endMaxLimit = 17 * 60 + 30;

    const minDuration = 30;
    const maxDuration = 120;

    final pickedMin = _toMinutes(picked);

    final dynamicStartMin = _isToday
        ? _toMinutes(TimeOfDay.now())
        : 7 * 60 + 30;
    if (selectedDate != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate!);

      final slots = widget.bookingsByDate[dateKey];

      if (slots != null) {
        for (final slot in slots) {
          final parts = slot.split(",");
          final start = _timeStringToMinutes(parts[0]);
          final end   = _timeStringToMinutes(parts[1]);

          if (pickedMin >= start && pickedMin <= end) {
            return "Selected time overlaps with existing booking";
          }
        }
      }
    }


    if (isStart) {
      if (pickedMin < dynamicStartMin) {
        return _isToday
            ? "Start time must be after current time"
            : "Start time must be after 7:30 AM";
      }
      if (pickedMin > startMaxLimit) {
        return "Start time must be before 4:30 PM";
      }
      if (endTime != null) {
        final endMin = _toMinutes(endTime!);
        if (pickedMin == endMin) return "Start and end time cannot be same";
        if (pickedMin > endMin) return "Start must be before end";
        final diff = endMin - pickedMin;
        if (diff < minDuration) return "Minimum duration is 30 minutes";
        if (diff > maxDuration) return "Maximum duration is 2 hours";
      }
    } else {
      if (pickedMin < endMinLimit) {
        return "End time must be after 8:30 AM";
      }
      if (pickedMin > endMaxLimit) {
        return "End time must be before 5:30 PM";
      }
      if (startTime != null) {
        final startMin = _toMinutes(startTime!);
        if (pickedMin == startMin) return "Start and end time cannot be same";
        if (pickedMin < startMin) return "End must be after start";
        final diff = pickedMin - startMin;
        if (diff < minDuration) return "Minimum duration is 30 minutes";
        if (diff > maxDuration) return "Maximum duration is 2 hours";
      }
    }
    return null;
  }

  Map<DateTime, String> blockedDates = {};

  Future<bool> validateDate(DateTime picked) async {
    DateTime normalized = DateTime(picked.year, picked.month, picked.day);

    if (!mounted) return false;

    if (blockedDates.containsKey(normalized)) {
      String reason = blockedDates[normalized]!;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PC unavailable: $reason"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }

    return true;
  }


  // var err_msg;

  @override
  void dispose() {
    mcount.dispose();
    super.dispose();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadBlockedDates();
    if (widget.minBookedTime != null &&
        widget.maxBookedTime != null) {
      bookedStartMin = _timeStringToMinutes(widget.minBookedTime!);
      bookedEndMin   = _timeStringToMinutes(widget.maxBookedTime!);
    }

    mname.add(TextEditingController());
    mid.add(TextEditingController());
    mdept.add(TextEditingController());
    mname_err.add(null);
    mid_err.add(null);
    mdept_err.add(null);
    msid_err.add(null);

  }

  Future<void> _loadBlockedDates() async {
    final snap = await FirebaseFirestore.instance
        .collection("BlockedDays")
        .where("facilityId", isEqualTo: "pc_${widget.pcnumber}")
        .get();

    setState(() {
      blockedDates = {
        for (var doc in snap.docs)
          DateTime(
            (doc["date"] as Timestamp).toDate().year,
            (doc["date"] as Timestamp).toDate().month,
            (doc["date"] as Timestamp).toDate().day,
          ): doc["reason"] ?? "No reason provided"
      };
    });
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
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              /// Total members input
              TextField(
                controller: mcount,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    membersCount = int.tryParse(value) ?? 1;
                    if(membersCount > 4){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Only 4 Members Allowed At A Time.",style: TextStyle(fontSize: 18,fontFamily: "Mono"),),backgroundColor: Colors.red,behavior: SnackBarBehavior.floating,),);}

                    while(mname.length < membersCount){
                      mname.add(TextEditingController());
                      mid.add(TextEditingController());
                      mdept.add(TextEditingController());
                    }
                    while(mname.length > membersCount){
                      mname.removeLast().dispose();
                      mdept.removeLast().dispose();
                      mid.removeLast().dispose();
                    }

                    while(mname_err.length < membersCount){
                      mname_err.add(null);
                      mid_err.add(null);
                      mdept_err.add(null);
                      msid_err.add(null);
                    }
                    while(mname_err.length > membersCount){
                      mname_err.removeLast();
                      mdept_err.removeLast();
                      mid_err.removeLast();
                      msid_err.removeLast();
                    }

                  });
                },
                decoration: InputDecoration(
                  labelText: "Total Members",
                  prefixIcon: const Icon(Icons.people),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF00796B),
                      width: 1.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.lightGreen,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30,),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  width: double.infinity,
                  height: selectedDate != null &&
                      startTime != null &&
                      endTime != null
                      ? 320
                      : 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFF00796B),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// DATE ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Select Date :",
                            style: TextStyle(
                              fontFamily: "Mono",
                              color: Color(0xFF007968),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 10,),
                          SizedBox(
                            width: 100,
                            child: TextButton(
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                                backgroundColor: WidgetStatePropertyAll(
                                  Color(0xFF007968),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.all(10),
                                ),
                              ),
                              onPressed: () async {
                                DateTime now = DateTime.now();
                                DateTime dayAfterTomorrow =
                                now.add(const Duration(days: 2));

                                DateTime? datePicked =
                                await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ??
                                      (_isAfterBookingHours
                                          ? now.add(
                                          const Duration(days: 1))
                                          : now),
                                  firstDate: _isAfterBookingHours
                                      ? DateTime(
                                      now.year,
                                      now.month,
                                      now.day + 1)
                                      : DateTime(
                                      now.year,
                                      now.month,
                                      now.day),
                                  lastDate: DateTime(
                                    dayAfterTomorrow.year,
                                    dayAfterTomorrow.month,
                                    dayAfterTomorrow.day,
                                  ),
                                );

                                if (datePicked != null) {
                                  bool isValid =
                                  await validateDate(datePicked);

                                  if (!isValid) return;

                                  setState(() {
                                    selectedDate = datePicked;
                                    startTime = null;
                                    endTime = null;
                                    timeError = null;
                                    dateError = null;
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.date_range,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (dateError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Date Required",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      /// TIME ROW
                      Row(
                        children: [
                          Text(
                            "Start Time :",
                            style: TextStyle(
                              fontFamily: "Mono",
                              color: Color(0xFF007968),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 20,),
                          SizedBox(
                            width: 100,
                            child: TextButton(
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                                backgroundColor:
                                WidgetStatePropertyAll(
                                  Color(0xFF007968),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.all(10),
                                ),
                              ),
                              onPressed: () async {
                                final picked =
                                await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                            
                                if (picked != null) {
                                  final error = validateTime(
                                    picked: picked,
                                    isStart: true,
                                  );
                            
                                  setState(() {
                                    if (error != null) {
                                      timeError = error;
                                    } else {
                                      startTime = picked;
                                      timeError = null;
                                    }
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.punch_clock_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Text(
                            "End Time :",
                            style: TextStyle(
                              fontFamily: "Mono",
                              color: Color(0xFF007968),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 30,),
                          SizedBox(
                            width: 100,
                            child: TextButton(
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                                backgroundColor:
                                WidgetStatePropertyAll(
                                  Color(0xFF007968),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.all(10),
                                ),
                              ),
                              onPressed: () async {
                                final picked =
                                await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (picked != null) {
                                  final error = validateTime(
                                    picked: picked,
                                    isStart: false,
                                  );

                                  setState(() {
                                    if (error != null) {
                                      timeError = error;
                                    } else {
                                      endTime = picked;
                                      timeError = null;
                                    }
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.punch_clock_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (timeError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          timeError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      /// SELECTED DETAILS
                      if (selectedDate != null &&
                          startTime != null &&
                          endTime != null) ...[
                        Text(
                          "Selected Date - ${DateFormat("yMd").format(selectedDate!)}",
                          style: const TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.w600,
                            fontFamily: "Mono",
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Start Time - ${formatTimeOfDay(startTime!)}",
                          style: const TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.w600,
                            fontFamily: "Mono",
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "End Time - ${formatTimeOfDay(endTime!)}",
                          style: const TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.w600,
                            fontFamily: "Mono",
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              /// Dynamic Member Inputs
              GridView.builder(
                shrinkWrap: true,
                itemCount: membersCount > 4 ? membersCount=4 : membersCount,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  mainAxisExtent: 305,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.only(left:15,right:15,top:15,bottom:5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF00796B),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10,),
                        TextField(
                          onChanged: (_){
                            setState(() {
                              if(mname_err[index]!=null){
                                mname_err[index]=null;
                              }
                            });
                          },
                          controller: mname[index],
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            errorText: mname_err[index],
                            labelText:
                            "Member ${index + 1} Name",
                            prefixIcon:
                            const Icon(Icons.person),
                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFF00796B),
                                width: 2,
                              ),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(
                                color: Colors.lightGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(onChanged: (_){
                          setState(() {
                            if(mid_err[index]!=null){
                              mid_err[index]=null;
                            }
                            if(msid_err[index]!=null){
                              msid_err[index]=null;
                            }
                          });
                        },
                          controller: mid[index],
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            errorText: mid_err[index] ?? msid_err[index],
                            labelText:
                            "Member ${index + 1} Student ID",
                            prefixIcon:
                            const Icon(Icons.badge),
                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFF00796B),
                                width: 2,
                              ),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(
                                color: Colors.lightGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          onChanged: (_){
                            setState(() {
                              if(mdept_err[index]!=null){
                                mdept_err[index]=null;
                              }
                            });
                          },
                          controller: mdept[index],
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            errorText: mdept_err[index],
                            labelText:
                            "Member ${index + 1} Department",
                            prefixIcon:
                            const Icon(Icons.badge),
                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFF00796B),
                                width: 2,
                              ),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(
                                color: Colors.lightGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );

                },
              ),
              // const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {

                    setState(() {
                      hasError = false;
                      timeError = null;
                      dateError = null;
                    });

                    membersInfo.clear();

                    for (int i = 0; i < membersCount; i++) {

                      if (mname[i].text.trim().isEmpty) {
                        mname_err[i] = "Member ${i + 1} Name Required";
                        hasError = true;
                      }

                      if (mid[i].text.trim().isEmpty) {
                        mid_err[i] = "Student Id of Member ${i + 1} Required";
                        hasError = true;
                      }

                      if (mid[i].text.trim().isNotEmpty &&
                          (mid[i].text.trim().length != 7 ||
                              !RegExp(r'^\d+$').hasMatch(mid[i].text))) {
                        msid_err[i] =
                        "Student Id Must be of 7 Letters and It Must Contain only Numbers";
                        hasError = true;
                      }

                      if (mdept[i].text.trim().isEmpty) {
                        mdept_err[i] = "Department Required for Member ${i + 1}";
                        hasError = true;
                      }

                      // ✅ Proper duplicate check
                      for (int j = i + 1; j < membersCount; j++) {
                        if (mid[i].text.trim().isNotEmpty &&
                            mid[i].text.trim() == mid[j].text.trim()) {
                          mid_err[i] = "Duplicate Sid";
                          mid_err[j] = "Duplicate Sid";
                          hasError = true;
                        }
                      }
                    }

                    if (startTime == null || endTime == null) {
                      timeError = "Time Required";
                      hasError = true;
                    }

                    if (selectedDate == null) {
                      dateError = "Date Required";
                      hasError = true;
                    }

                    if (hasError) {
                      setState(() {}); // refresh UI

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "All Fields are Required.!",
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Mono",
                                color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return; // 🔴 STOP HERE — no loader, no booking
                    }

                    // ✅ Start loader ONLY after validation success
                    setState(() {
                      loading = true;
                    });

                    try {

                      for (int i = 0; i < membersCount; i++) {
                        membersInfo.add({
                          "name": mname[i].text.trim(),
                          "studentId": mid[i].text.trim(),
                          "department": mdept[i].text.trim(),
                        });
                      }

                      final User? user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        setState(() { loading = false; });
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => Signinpage()));
                        return;
                      }

                      String userEmail = user.email ?? "";
                      String userUid = user.uid;

                      final querySnapshot = await FirebaseFirestore.instance
                          .collection("Users")
                          .where("email", isEqualTo: userEmail)
                          .get();

                      if (querySnapshot.docs.isEmpty) {
                        setState(() { loading = false; });
                        return;
                      }

                      String userFullName =
                          querySnapshot.docs.first.data()['fullname'] ?? "";

                      // 🔥 SEND OTP FIRST
                      final prefs = await SharedPreferences.getInstance();
                      String? em = prefs.getString("email");
                      otp_email = em ?? "";

                      final url = Uri.parse('https://resourcely-5.onrender.com/user/send-slot-otp');

                      final response = await http.post(
                        url,
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "email": userEmail,
                          "pcnumber": widget.pcnumber,
                          "bookingDate": DateFormat("yyyy-MM-dd").format(selectedDate!),
                          "startTime": formatTimeOfDay(startTime!),
                          "endTime": formatTimeOfDay(endTime!),
                        }),
                      );

                      if (response.statusCode != 200) {
                        setState(() { loading = false; });
                        print(response.body);
                        print(response.statusCode);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Failed to send Otp!",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: "Mono"),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return; // 🔴 STOP — no booking
                      }

                      // ✅ BOOK ONLY IF OTP SUCCESS
                      await FirebaseFirestore.instance
                          .collection("PcRoom")
                          .doc("${DateTime.now()}")
                          .set({
                        "Members": membersCount,
                        "Members_Info": membersInfo,
                        "date": Timestamp.fromDate(selectedDate!),
                        "startTime": startTime!.format(context),
                        "endTime": endTime!.format(context),
                        "status": "booked",
                        "pcnumber": widget.pcnumber,
                        "user_name": userFullName,
                        "uid": userUid,
                        "user_email": userEmail
                      });
                      // final prefss=await SharedPreferences.getInstance();
                      // prefss.setBool("close", true);

                      setState(() { loading = false; });

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Icon(Icons.check_circle,
                              color: Colors.green, size: 100),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Booking Successful.",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 10),
                              Text(
                                "Otp has been sent to User's Email.\nVerify Later at Check-in.",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                              )
                            ],
                          ),
                        ),
                      );

                      Timer(Duration(seconds: 3), () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => Homepage()));
                      });

                    } catch (e) {

                      setState(() { loading = false; });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Something went wrong!",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: "Mono"),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF00796B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading ? CircularProgressIndicator(color: Colors.white,) : const Text(
                    "Book Slot",
                    style: TextStyle(fontSize: 18, fontFamily: "Mono"),
                  ),
                ),
              ),


              // SizedBox(height: 30,),

            ],
          ),
        ),
      ),
    );
  }
}