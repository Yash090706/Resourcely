
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/Email_Signin_Otp.dart";
import "package:flutter_firebase/FlutterProject/HomePage.dart";
import "package:flutter_firebase/FlutterProject/PcBookingPage.dart";
// <<<<<<< HEAD
import "package:flutter_firebase/FlutterProject/PcroomCoverPage.dart";
import "package:flutter_firebase/FlutterProject/Res_ProfilePage.dart";
// =======
// >>>>>>> origin/profile-merge-fix
import "package:flutter_firebase/FlutterProject/SignInPage.dart";
import "package:flutter_firebase/FlutterProject/SignupPage.dart";
import "package:flutter_firebase/FlutterProject/SplashPage.dart";
import "package:flutter_firebase/FlutterProject/admin_dashboard.dart";
import "package:flutter_firebase/FlutterProject/admin_side_total_bookings.dart";
import "package:flutter_firebase/FlutterProject/auth_wrapper.dart";
// <<<<<<< HEAD
// =======
import "package:flutter_firebase/FlutterProject/facility_details_page.dart";
import "package:flutter_firebase/FlutterProject/profile_page.dart";


// >>>>>>> origin/profile-merge-fix
import "package:flutter_firebase/Widgets/AddData.dart";
import "package:flutter_firebase/Widgets/CounterProvider.dart";
// import "package:flutter_firebase/Widgets/Homepage.dart";
import "package:flutter_firebase/Widgets/PhoneAuth.dart";
import "package:flutter_firebase/Widgets/StateManagement1.dart";
import "package:flutter_firebase/Widgets/TabConcept.dart";
import "package:provider/provider.dart";
import 'firebase_options.dart';
void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
// <<<<<<< HEAD
//       home:Homepage(),
// =======
// >>>>>>> origin/profile-merge-fix
      theme:ThemeData(fontFamily: "Mono"),
      debugShowCheckedModeBanner: false,
      home:Splashpage(),


    );
  }
}
// <<<<<<< HEAD


// =======
// >>>>>>> origin/profile-merge-fix
