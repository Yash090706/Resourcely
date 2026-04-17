import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/Email_Signin_Otp.dart";
import "package:flutter_firebase/FlutterProject/HomePage.dart";
import "package:flutter_firebase/FlutterProject/SignupPage.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter_firebase/FlutterProject/auth_wrapper.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:shared_preferences/shared_preferences.dart";

class Signinpage extends StatefulWidget {
  String? username="";
  Signinpage();

  @override
  State<Signinpage> createState() => _SigninpageState();
}

class _SigninpageState extends State<Signinpage> {
  final password=TextEditingController();
  final email=TextEditingController();
  String? msg;
  String?em_err_msg;
  String?ps_err_msg;
  String?college_email;
  String?pass_ch;
  bool obsecure=true;
  bool isloading=false;
  String? email_exists;
  Future<void> continueWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      // 🔴 Important: force fresh login (fixes many issues)
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      if (googleUser == null) {
        print("User cancelled sign-in");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      print("AccessToken: $accessToken");
      print("IdToken: $idToken");

      // 🔴 Safety check
      if (accessToken == null || idToken == null) {
        throw Exception("Google tokens are null → config issue");
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      await saveUserToFirestore(userCredential);

    } catch (e) {
      print("Google Sign-In Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveUserToFirestore(UserCredential userCredential) async {
    final user = userCredential.user!;
    final userEmail = user.email ?? "";

    if (!userEmail.endsWith("@ves.ac.in")) {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Only College email is allowed",
            style: TextStyle(fontSize: 16, fontFamily: "Mono", color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userRef =
    FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        "fullname": user.displayName,
        "email": user.email,
        "role":"Student",
        "authProvider": "google",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "User Signed Up SuccessFully!",
            style: TextStyle(fontSize: 16, fontFamily: "Mono", color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "User Signed In SuccessFully!",
            style: TextStyle(fontSize: 16, fontFamily: "Mono", color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => AuthWrapper()));
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
        body:SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.only(top:80),
            child: Column(
              children: [
                TextField(
                  controller: email,
                  onChanged: (_){
                    if(em_err_msg!=null){
                      setState(() {
                        em_err_msg=null;
                      });
                    }
                    if(college_email!=null){
                      setState(() {
                        college_email=null;
                      });
                    }
                    if(email_exists!=null){
                      setState(() {
                        email_exists=null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                      errorText: em_err_msg!=null ? em_err_msg : college_email,
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
                SizedBox(height: 20,),TextField(
                  onChanged:(_){
                    if(ps_err_msg!=null){
                      setState(() {
                        ps_err_msg=null;
                      });
                    }
                    if(pass_ch!=null){
                      setState(() {
                        pass_ch=null;
                      });
                    }

                  },
                  controller: password,
                  obscureText: obsecure,
                  decoration: InputDecoration(
                      labelText: "Password",
                      errorText: ps_err_msg!=null?ps_err_msg :pass_ch,
                      errorBorder:OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 3
                          )) ,
                      prefixIcon: Icon(Icons.lock,color: Colors.grey,),
                      suffixIcon: IconButton(onPressed:(){
                        setState(() {
                          obsecure=!obsecure;                      });
                      }, icon: obsecure?Icon(Icons.remove_red_eye,color: Color(0xFF00796B),):Icon(Icons.visibility_off,color: Color(0xFF00796B),),),
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
                SizedBox(height: 30,),
                SizedBox(
                  width:double.infinity,
                  child: ElevatedButton(
                    onPressed: () async{
                      String pass=password.text.trim();
                      String c_email=email.text.trim();
                      if(c_email.isEmpty){
                        setState(() {
                          em_err_msg="Email Required.";
                        });
                        return;
                      }
                      if(pass.isEmpty){
                        setState(() {
                          ps_err_msg="Password Required.";
                        });
                        return;
                      }
                      if(!email.text.endsWith("@ves.ac.in")){
                        setState(() {
                          college_email="Only College Email Accepted.";
                        });
                        return;
                      }
                      if(password.text.length<8){
                        setState(() {
                          pass_ch="Password should contain atleast 8 Characters.";
                        });
                        return;
                      }
                      try{
                        setState(() {
                          isloading=true;
                        });
                        await FirebaseAuth.instance.signInWithEmailAndPassword(email: c_email, password: pass);

                        print("User Signed in Succesffully!");
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Signed In SuccessFully!",
                          style: TextStyle(fontSize:16,fontFamily: "Mono",color: Colors.white),)
                          ,backgroundColor: Colors.green,behavior: SnackBarBehavior.floating,),);

                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
                          return AuthWrapper();
                        }));

                        final user = FirebaseAuth.instance.currentUser;

                        final doc = await FirebaseFirestore.instance
                            .collection("Users")
                            .doc(user!.uid)
                            .get();

                        final username = doc["fullname"];
                        final email=doc["email"];
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setString("username", username);

                        final prefss=await SharedPreferences.getInstance();
                        prefss.setString("email", email ?? c_email);
                        print("Email Saved ${prefss.getString("email")}");
                      }on FirebaseAuthException
                      catch(err){
                        print("Err code :${err.code}");
                        if (err.code == 'user-not-found') {
                          msg = "User does not exist";
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${msg}!",
                            style: TextStyle(fontSize:16,fontFamily: "Mono",color: Colors.white),)
                            ,backgroundColor: Colors.red,behavior: SnackBarBehavior.floating,),);
                          return;
                        } else if (err.code == 'invalid-credential') {
                          msg = "Invalid Credentials.";
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${msg}!",
                            style: TextStyle(fontSize:16,fontFamily: "Mono",color: Colors.white),)
                            ,backgroundColor: Colors.red,behavior: SnackBarBehavior.floating,),);
                          return;
                        } else if (err.code == 'invalid-email') {
                          msg = "Invalid email format";
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${msg}!",
                            style: TextStyle(fontSize:16,fontFamily: "Mono",color: Colors.white),)
                            ,backgroundColor: Colors.red,behavior: SnackBarBehavior.floating,),);
                          return;
                        } else {
                          msg = err.message;
                          print("Message - ${msg}");
                          return;
                        }


                      }
                      finally{
                        setState(() {
                          isloading = false;
                        });
                      }
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
                    child: isloading ? CircularProgressIndicator(color: Colors.white,):Text(
                      "Sign In",
                      style: TextStyle(
                        fontFamily: "Mono",
                        fontSize: 20,

                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Text("Or", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                          overlayColor: WidgetStatePropertyAll(Colors.white),
                          padding: WidgetStatePropertyAll(EdgeInsets.all(11)),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius:BorderRadius.circular(11),side: BorderSide(color: Color(0xFF00796B))))

                      ),
                      onPressed: continueWithGoogle,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(
                                "https://tse3.mm.bing.net/th/id/OIP.uBYsSL7JDekYP3VpxWZvYQHaHa?pid=Api&P=0&h=220",
                              ),
                            ),
                          ),
                          Text(
                            "Continue with Google",
                            style: TextStyle(
                              color: Color(0xFF00796B),
                              fontFamily: "Mono",
                              fontSize: 18,
                            ),
                          ),
                        ],
                      )
                  ),
                ),
                // SizedBox(
                //   child: Text("Or",style: TextStyle(fontWeight: FontWeight.bold),),
                // ),
                // SizedBox(
                //   height: 15,
                // ),
                // SizedBox(
                //   width:double.infinity,
                //   child: ElevatedButton(style:ButtonStyle(
                //       backgroundColor: WidgetStatePropertyAll(Colors.white),
                //       overlayColor: WidgetStatePropertyAll(Colors.white),
                //       padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
                //     shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius:BorderRadius.circular(11),side: BorderSide(color: Color(0xFF00796B))))
                //
                //   ),onPressed: (){
                //     Navigator.push(context,MaterialPageRoute(builder: (context){
                //       return EmailSigninOtp();
                //     }));
                //   }, child:Wrap(
                //     children: [
                //       Container(child: Icon(Icons.fiber_pin_rounded,size: 30,color: Color(0xFF00796B),)),
                //       SizedBox(width:30),
                //       Container(child: Text("Verify Via OTP",style: TextStyle(color:Color(0xFF00796B),fontFamily: "Mono",fontSize: 18,),))
                //     ],
                //   )),
                // ),
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top:15,left:5),
                      child: Text("New User? ",style: TextStyle(fontSize: 17,fontFamily: "Mono",),),
                    ),
                    InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context){
                          return Signuppage();
                        }));
                      },
                      child: Container( margin: EdgeInsets.only(top:15),
                          child: Text("Sign Up",style: TextStyle(fontSize: 20,fontFamily: "Mono",
                              decoration: TextDecoration.underline,decorationColor: Colors.redAccent,
                              color:Colors.redAccent))),
                    )
                  ],
                ),

              ],
            ),
          ),
        )

    );
  }
}