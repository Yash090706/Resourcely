import "dart:async";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/HomePage.dart";
import "package:flutter_firebase/FlutterProject/SignInPage.dart";
import "package:flutter_firebase/FlutterProject/auth_wrapper.dart";
import "package:flutter_firebase/FlutterProject/navigationBar.dart";
import "package:google_sign_in/google_sign_in.dart";

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final fullname = TextEditingController();
  final password = TextEditingController();
  final email = TextEditingController();

  String? fn_err_msg;
  String? em_err_msg;
  String? ps_err_msg;
  String? college_email;
  String? pass_ch;
  String? email_exists;

  bool obsecure = true;
  bool isloading = false;

  /* ---------------- GOOGLE SIGN IN ---------------- */

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

  /* ---------------- EMAIL SIGNUP (UNCHANGED VALIDATION + UI) ---------------- */

  Future<void> signupWithEmail() async {
    String fname = fullname.text.trim();
    String pass = password.text.trim();
    String c_email = email.text.trim();

    if (fname.isEmpty) {
      setState(() => fn_err_msg = "Fullname Required.");
      return;
    }

    if (c_email.isEmpty) {
      setState(() => em_err_msg = "Email Required.");
      return;
    }

    if (!c_email.endsWith("@ves.ac.in")) {
      setState(() => college_email = "Only College Email Accepted.");
      return;
    }

    if (pass.isEmpty) {
      setState(() => ps_err_msg = "Password Required.");
      return;
    }

    if (pass.length < 8) {
      setState(() =>
      pass_ch = "Password should contain atleast 8 Characters.");
      return;
    }

    final checkEmail = await FirebaseFirestore.instance
        .collection("Users")
        .where("email", isEqualTo: c_email)
        .get();

    if (checkEmail.docs.isNotEmpty) {
      email_exists = "Email Already Exists.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            email_exists!,
            style: TextStyle(fontSize: 16, fontFamily: "Mono", color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => isloading = true);

      UserCredential userCred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: c_email,
        password: pass,
      );

      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCred.user!.uid)
          .set({
        "fullname": fname,
        "email": c_email,
        "role":"Student",
        "SignedUpAt": FieldValue.serverTimestamp(),
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

      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Signinpage()));
      });
    } on FirebaseAuthException catch (err) {
      print("Err Code: ${err.code}");
      print("Err Message: ${err.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "User Signed Up Failed!",
            style: TextStyle(fontSize: 16, fontFamily: "Mono", color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isloading = false);
    }
  }

  /* ---------------- UI (UNCHANGED) ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resourcely",
            style: TextStyle(
                fontSize: 20,
                fontFamily: "Mono",
                fontWeight: FontWeight.w500)),
        backgroundColor: Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body:SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.only(top:70,left:10,right:10),
          // margin: EdgeInsets.only(top: 80),
          child: Column(
            children: [
              TextField(
                controller: fullname,
                onChanged: (_){
                  if(fn_err_msg!=null){
                    setState(() {
                      fn_err_msg=null;
                    });
                  }
                },
                decoration: InputDecoration(
                    labelText: "Full Name",
                    errorText: fn_err_msg,
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: Colors.red,
                            width: 3
                        )
                    ),
                    prefixIcon: Icon(Icons.person,color: Colors.grey,),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: Color(0xFF00796B),
                            width: 3
                        )
                    ),
                    labelStyle: TextStyle(color: Colors.grey,fontFamily: "Mono"),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.lightGreen,
                            width: 3
                        )
                    )
                ),
              ),
              SizedBox(height: 20),
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
                    labelStyle: TextStyle(color: Colors.grey,fontFamily: "Mono"),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.lightGreen,
                            width: 3
                        )
                    )
                ),
              ),
              SizedBox(height: 20,)
              ,TextField(
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
                    errorText: ps_err_msg!=null?ps_err_msg :pass_ch,
                    errorBorder:OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: Colors.red,
                            width: 3
                        )) ,
                    labelText: "Password",
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
                    labelStyle: TextStyle(color: Colors.grey,fontFamily: "Mono"),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.lightGreen,
                            width: 3
                        )
                    )
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isloading ? null : signupWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00796B),
                    padding: EdgeInsets.all(18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))
                  ),
                  child: isloading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Sign Up",
                      style: TextStyle(
                          fontFamily: "Mono",
                          fontSize: 20,
                          color: Colors.white)),
                ),
              ),
              SizedBox(height: 15),
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
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(top:15,left:5),
                    child: Text("Already User? ",style: TextStyle(fontSize: 17,fontFamily: "Mono",),),
                  ),
                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                        return Signinpage();
                      }));
                    },
                    child: Container( margin: EdgeInsets.only(top:15),
                        child: Text("Sign In",style: TextStyle(fontSize: 20,fontFamily: "Mono",
                            decoration: TextDecoration.underline,decorationColor: Colors.green,
                            color:Colors.green))),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}