import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/SignInPage.dart";
import "package:flutter_firebase/FlutterProject/SignupPage.dart";
import "package:flutter_firebase/FlutterProject/auth_wrapper.dart";

class Splashpage extends StatefulWidget {
  const Splashpage({super.key});

  @override
  State<Splashpage> createState() => _SplashpageState();
}

class _SplashpageState extends State<Splashpage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 3), (){

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
        return AuthWrapper();
      }));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00796B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage:AssetImage("Assets/Images/Resourcelylogo1.png"),
              radius: 70,
            ),
            SizedBox(height: 20,),
            Text("Loading Resourcely..",style: TextStyle(fontSize: 18,fontFamily: "Mono",fontWeight: FontWeight.w500,color: Colors.white),),
            SizedBox(height: 15,),
            CircularProgressIndicator(color: Colors.white,),
          ],
        ),
      ),
    );
  }
}
