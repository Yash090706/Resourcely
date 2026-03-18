import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/FlutterProject/Res_ProfilePage.dart';
import 'package:flutter_firebase/FlutterProject/SignInPage.dart';
import 'package:flutter_firebase/FlutterProject/SplashPage.dart';
import 'package:flutter_firebase/FlutterProject/auth_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resourcely_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final userId  = FirebaseAuth.instance.currentUser!.uid;
  String uname="";
  final fullname=TextEditingController();
  final email=TextEditingController();
  final password=TextEditingController();


  // String num="";
  // void delete_user_account(){
  //
  // }
  void get_username()async{
    final prefs=await SharedPreferences.getInstance();
    setState(() {
      uname=prefs.getString("username")??"User";
      fullname.text=uname;
      // uname=unm;

    });
  }
  void get_email_pass()async{
    final user=FirebaseAuth.instance.currentUser;
    final doc=await FirebaseFirestore.instance.collection("Users").doc(user!.uid).get();
    // final preffs=await SharedPreferences.getInstance();
    // String? em=preffs.getString("email");
    email.text=doc["email"];
    // password.text=doc["password"];

  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    get_email_pass();
    get_username();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile",style:TextStyle(color: Colors.white,fontFamily: "Mono")),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String role = data['role'] ?? "student";


          final String name = data['fullname'] ?? "User";
          final String email = data['email'] ?? "-";
          final Timestamp createdAt =data['SignedUpAt' ] ?? data['createdAt'];

          final String joinedDate =
          DateFormat('dd MM yyyy').format(createdAt.toDate());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // 👤 Profile Avatar
                CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF00796B),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 👤 Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // 📧 Email
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 20),

                // 📄 Info Cards
                _infoTile(
                  icon: Icons.calendar_today,
                  title: "Joined On",
                  value: joinedDate,
                ),

                const SizedBox(height: 12),

                _infoTile(
                  icon: Icons.verified_user,
                  title: "Account Type",
                  value: role,
                ),

                const SizedBox(height: 12),


                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Reset Password"),
                        content: Text("Do you want to reset your password?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("No",style: TextStyle(color: Color(0xFF00796B)),),
                          ),
                          TextButton(
                            onPressed: () async{
                              final mail = email;

                              if (mail.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Please enter your email"),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Password reset link sent",style: TextStyle(color: Colors.white,fontFamily: "Mono",fontSize: 16,),),
                                    backgroundColor:Colors.green,behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(e.message ?? "Failed to send link"),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              // YES logic
                            },
                            child: Text("Yes",style:TextStyle(color: Color(0xFF00796B)),),
                          ),
                        ],
                      ),
                    );

                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F2FA),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_reset,
                          color: Colors.teal,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Reset Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 30),


                // 🚪 Logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.red.shade600,
                      backgroundColor: Color(0xFF00796B),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) =>  const AuthWrapper()),
                            (route) => false,
                      );
                    },

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color:Colors.white,
                            fontFamily: "Mono"
                          ),
                        ),
                        SizedBox(width: 3,),
                        Icon(Icons.logout_outlined,color: Colors.white,),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Text("Or", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(style:ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      padding: WidgetStatePropertyAll(EdgeInsets.all(15))
                  ),

                      onPressed: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final userEmail = user.email;

                          // 🔴 1️⃣ Delete bookings from PcRoom collection
                          if (userEmail != null) {
                            final bookingSnapshot = await FirebaseFirestore.instance
                                .collection("PcRoom")
                                .where("user_email", isEqualTo: userEmail)
                                .get();

                            for (var doc in bookingSnapshot.docs) {
                              await doc.reference.delete();
                            }
                          }

                          // 🔴 2️⃣ Delete user document from Users collection
                          await FirebaseFirestore.instance
                              .collection("Users")
                              .doc(user.uid)
                              .delete();

                          // 🔴 3️⃣ Delete user from Firebase Authentication
                          await user.delete();

                          // 🔴 4️⃣ Sign out
                          await FirebaseAuth.instance.signOut();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account & Bookings Deleted Successfully"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Signinpage()
                            ),
                                (route) => false,
                          );

                        } on FirebaseAuthException catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? "Deletion Failed"),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                      , child: Text("Delete Account ?",style: TextStyle(fontSize: 18,fontFamily: "Mono",fontWeight: FontWeight.w600),)),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00796B)),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
