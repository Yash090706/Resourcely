import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_firebase/FlutterProject/HomePage.dart";

class EmailSigninOtp extends StatefulWidget {
  const EmailSigninOtp({super.key});

  @override
  State<EmailSigninOtp> createState() => _EmailSigninOtpState();
}

class _EmailSigninOtpState extends State<EmailSigninOtp> {
  final phone_controller = TextEditingController();
  final otp_controller = TextEditingController();

  bool isloading = false;
  bool isFirst = true;

  String verificationId = "";

  Future<void> sendOtp() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91${phone_controller.text.trim()}",

        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Homepage()),
          );
        },

        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            isloading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.message ?? "OTP Failed",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: "Mono",
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },

        codeSent: (String verId, int? resendToken) {
          setState(() {
            verificationId = verId;
            isloading = false;
            isFirst = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "OTP Sent Successfully!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: "Mono",
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },

        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );
    } catch (e) {
      setState(() {
        isloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Something went wrong!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: "Mono",
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> validate_otp() async {
    try {
      PhoneAuthCredential credential =
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp_controller.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = FirebaseAuth.instance.currentUser;
      print("Firebase UID: ${user?.uid}");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Homepage()),
      );

      setState(() {
        isloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "OTP Verified Successfully!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: "Mono",
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        isloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid OTP",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: "Mono",
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    phone_controller.dispose();
    otp_controller.dispose();
    super.dispose();
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
      body: Container(
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(35),
          margin: const EdgeInsets.only(top: 90),
          child: Column(
            children: [
              AnimatedCrossFade(
                firstChild: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: phone_controller,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF00796B),
                              width: 3,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.lightGreen,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isloading = true;
                            });

                            await sendOtp();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
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
                ),
                secondChild: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: otp_controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Otp",
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF00796B),
                              width: 3,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.lightGreen,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isloading = true;
                            });

                            await validate_otp();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
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
                ),
                crossFadeState: isFirst
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(seconds: 1),
              ),
              const SizedBox(height: 30),
              isloading
                  ? const CircularProgressIndicator(
                color: Color(0xFF00796B),
              )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}