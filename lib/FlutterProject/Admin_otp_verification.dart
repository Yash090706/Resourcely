import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'CurrentFacilityUsing.dart';
import 'HomePage.dart';

class AdminOtpVerification extends StatefulWidget {
  final Map<String, dynamic> booking;

  const AdminOtpVerification({required this.booking, super.key});

  @override
  State<AdminOtpVerification> createState() => _AdminOtpVerificationState();
}

class _AdminOtpVerificationState extends State<AdminOtpVerification> {
  // final email_controller=TextEditingController();
  final otp_controller=TextEditingController();
  bool loading=false;

  Future<void> verifyOtp(String enteredOtp) async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      DateTime date;

      if (widget.booking['date'] is Timestamp) {
        date = (widget.booking['date'] as Timestamp).toDate();
      } else {
        date = widget.booking['date'];
      }

      final bookingDate = date.toIso8601String().split("T")[0];

      final response = await http.post(
        Uri.parse('https://resourcely-5.onrender.com/user/verify-slot-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.booking['email'],
          "pcnumber": widget.booking['pcnumber'],   // ✅ FIXED (not title)
          "bookingDate": bookingDate,
          "startTime": widget.booking['startTime'], // ✅ match firestore
          "endTime": widget.booking['endTime'],
          "otp": enteredOtp.trim(),
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {

        // ✅ UPDATE FIRESTORE USING QUERY
        final querySnapshot = await FirebaseFirestore.instance
            .collection("PcRoom")
            .where("user_email", isEqualTo: widget.booking['email'])
            .where("pcnumber", isEqualTo: widget.booking['pcnumber'])
            .where("startTime", isEqualTo: widget.booking['startTime'])
            .where("endTime", isEqualTo: widget.booking['endTime'])
            .get();

        for (var doc in querySnapshot.docs) {
          print(doc.data());
          await doc.reference.update({
            "status": "active",
            "verifiedAt": FieldValue.serverTimestamp(),
          });
        }
        if (!mounted) return;

        // ✅ SUCCESS SNACKBAR
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP Verified Successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Currentfacilityusing(),
          ),
        );

      } else {
        throw Exception(data["message"]);
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Resourcely",style:TextStyle(fontSize: 20,fontFamily: "Mono",fontWeight: FontWeight.w500),),
          backgroundColor: Color(0xFF00796B),
          foregroundColor: Colors.white,
        ),
        body:Container(
          margin: EdgeInsets.only(top:70),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: TextField(
                  controller: otp_controller,
                  decoration: InputDecoration(
                    // errorText: em_err_msg!=null ? em_err_msg : college_email,
                      errorBorder:OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 3
                          )) ,
                      labelText: "Enter Otp",
                      prefixIcon: Icon(Icons.pin,color: Colors.grey,),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: Color(0xFF00796B),
                              width: 3
                          )),
                      labelStyle: TextStyle(color:Colors.grey,fontFamily: "Mono"),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.lightGreen,
                              width: 3
                          )
                      )
                  ),
                ),
              ),
              // SizedBox(height: 30,),
              SizedBox(
                width:double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left:50,right:55),
                  child: ElevatedButton(
                    onPressed: () {
                      verifyOtp(otp_controller.text.toString().trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      overlayColor: Colors.green,
                      padding: EdgeInsetsGeometry.all(18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child:Text(
                      "Verify",
                      style: TextStyle(
                        fontFamily: "Mono",
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              // ElevatedButton(onPressed: (){
              //   Navigator.push(context, MaterialPageRoute(builder: (context){
              //     return Currentfacilityusing();
              //   }));
              // }, child: Text("view"))
            ],
          ),
        )
    );
  }
}