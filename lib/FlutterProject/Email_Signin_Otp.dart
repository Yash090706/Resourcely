// import "package:email_auth/email_auth.dart";
// import "dart:nativewrappers/_internal/vm/lib/async_patch.dart" hide Timer;
import "dart:async";
import "dart:convert";

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/HomePage.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:http/http.dart' as http;
import "package:shared_preferences/shared_preferences.dart";
// import "package:firebase_auth/firebase_auth.dart";
class EmailSigninOtp extends StatefulWidget {
  const EmailSigninOtp({super.key});

  @override
  State<EmailSigninOtp> createState() => _EmailSigninOtpState();
}

class _EmailSigninOtpState extends State<EmailSigninOtp> {
  final email_controller=TextEditingController();
  final otp_controller=TextEditingController();
  bool isloading=false;

  Future<void> sendOtpIfUserExists() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email_controller.text.toString().trim())
          .get();

      final bool exists = querySnapshot.docs.isNotEmpty;

      if (exists) {
        final url = Uri.parse('https://resourcely-5.onrender.com/user/send-otp');

        try {
          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email_controller.text.toString().trim(),
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('OTP sent successfully: ${data['msg']}');

            setState(() {
              isloading = false;
              isFirst = false; // 🔥 switch to OTP screen
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Otp sent to Registered Email!",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: "Mono"),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            final data = jsonDecode(response.body);

            setState(() {
              isloading = false;
            });

            print('Error: ${data['message'] ?? 'Unknown error'}');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Failed to send Otp!",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: "Mono"),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          setState(() {
            isloading = false;
          });

          print('Error sending OTP: $e');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to send Otp!",
                style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: "Mono"),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          isloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "User Not Found!",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Mono",
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isloading = false;
      });

      print('Error checking email: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong!",
            style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: "Mono"),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  void validate_otp()async{
    var v_url="https://resourcely-5.onrender.com/user/verify-otp";
    try{
      final otp_data={
        "email":email_controller.text.toString().trim(),
        "otp":otp_controller.text.toString().trim()
      };
      var response=await http.post(Uri.parse(v_url),body: jsonEncode(otp_data),
        headers: {"Content-Type": "application/json"},);

      var msg=jsonDecode(response.body);
      if (msg["success"] == true) {
        final token = msg["token"];

        await FirebaseAuth.instance.signInWithCustomToken(token);

        // 🔥 NOW USER EXISTS
        final user = FirebaseAuth.instance.currentUser;
        print("Firebase UID: ${user!.uid}");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Homepage()),
        );
        setState(() {
          isloading=false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Otp Verified Successfully!",
              style: TextStyle(fontSize: 16, color: Colors.white,fontFamily: "Mono"),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // if(msg["success"]==true){

      //   //
      //   // final prefss=await SharedPreferences.getInstance();
      //   // prefss.setString("email", email_controller.text.toString().trim() );
      //   // print("Email Saved ");
      //   //
      //   // final snapshot=await FirebaseFirestore.instance.collection("Users").where("email",isEqualTo: email_controller.text.toString().trim()).limit(1).get();
      //   // if(snapshot.docs.isNotEmpty){
      //   //   prefss.setString("username", snapshot.docs.first["fullname"]);
      //   //   print("set fullname ");
      //   // }
      //   //
      //
      //
      //   // CircularProgressIndicator();
      //  Timer(Duration(seconds: 4), (){
      //    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context){
      //      return Homepage();
      //    }));
      //  });
      //  setState(() {
      //    isloading=false;
      //  });
      // }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Invalid Otp",
              style: TextStyle(fontSize: 16, color: Colors.white,fontFamily: "Mono"),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

      }

    }
    catch(err){
      print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something Went Wrong",
            style: TextStyle(fontSize: 16, color: Colors.white,fontFamily: "Mono"),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

    }


  }
  bool isFirst=true;
  void reload(){
    setState(() {
      isloading=false;
    });
    setState(() {
      isFirst=false;
      // isloading=false;
    });
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
          color:Colors.white,
          child: Container(
            padding: EdgeInsets.all(35),
            margin: EdgeInsets.only(top:90),
            // color: Colors.green,
            child: Column(
              children: [
                AnimatedCrossFade(firstChild: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: email_controller,
                        decoration: InputDecoration(
                          // errorText: em_err_msg!=null ? em_err_msg : college_email,
                            errorBorder:OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 3
                                )) ,
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email,color: Colors.grey,),
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
                    SizedBox(height: 30,),
                    SizedBox(
                      width:double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isloading = true;
                            });

                            await sendOtpIfUserExists(); // 🔥 important
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
                            "Send",
                            style: TextStyle(
                              fontFamily: "Mono",
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ), secondChild: Column(
                  children: [
                    Container(
                      // margin:EdgeInsets.only(top:0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: otp_controller,
                          // obscureText: obsecure,
                          decoration: InputDecoration(
                              labelText: "Otp",
                              // errorText: ps_err_msg!=null?ps_err_msg :pass_ch,
                              errorBorder:OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                      color: Colors.red,
                                      width: 3
                                  )) ,
                              prefixIcon: Icon(Icons.lock,color: Colors.grey,),
                              // suffixIcon: IconButton(onPressed:(){
                              //   setState(() {
                              //     obsecure=!obsecure;                      });
                              // }, icon: obsecure?Icon(Icons.remove_red_eye,color: Color(0xFF00796B),):Icon(Icons.visibility_off,color: Color(0xFF00796B),),),
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
                    ), SizedBox(height: 30,),SizedBox(
                      width:double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // send_otp();
                            validate_otp();
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
                  ],
                ), crossFadeState: isFirst?CrossFadeState.showFirst :CrossFadeState.showSecond, duration:Duration(seconds:1)),

                Container(
                    child:isloading ? CircularProgressIndicator(color: Color(0xFF00796B),) :Text("")
                )







              ],
            ),
          ),
        )

    );
  }
}
