
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/allScreen/registerationScreen.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/main.dart';

import 'mainScreen.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen='login';
  TextEditingController emailTextEditingController=TextEditingController();
  TextEditingController passwordTextEditingController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:SafeArea(
        child:  ListView(
          children: [
            Column(
              children: [
                SizedBox(height: 35.0,),
                Image(
                  image: AssetImage('images/logo.png'),
                  width: 390.0,height: 250.0,
                  alignment: Alignment.center,
                ),
                SizedBox(height: 1.0,),
                Text('Login as a rider',style: TextStyle(fontSize: 24.0,
                    fontFamily: 'bolt-regular',fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding:EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 1.0,),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                            fontSize: 14.0
                        ),
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0
                        ),
                      ),
                      style: TextStyle(
                          fontSize: 14.0
                      ),
                    ),
                    SizedBox(height: 1.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                            fontSize: 14.0
                        ),
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0
                        ),
                      ),
                      style: TextStyle(
                          fontSize: 14.0
                      ),
                    ),
                    SizedBox(height:25.0,),
                    RaisedButton(
                        onPressed: (){
                          if(!emailTextEditingController.text.contains('@'))
                          {
                            displayToastMessage('Email address is not valid', context);
                          }
                          else if(passwordTextEditingController.text.isEmpty)
                          {
                            displayToastMessage('Password number is necessary', context);
                          }
                          else
                            {
                              loginAndAuthenticateUser(context);
                            }

                        },
                    color: Colors.yellow,
                      textColor: Colors.black,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text(
                            'Login',style: TextStyle(
                              fontSize: 18.0,fontFamily: 'bolt-regular',
                          fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                    ),
                  ],
                ),
                ),
                 FlatButton(
                     onPressed: (){
                       Navigator.pushNamedAndRemoveUntil(context, RegisterationScreen.idScreen, (route) => false);
                     },
                     child: Text(
                       'Do not have an account ? Register here',
                       style: TextStyle(
                         fontWeight: FontWeight.bold
                       ),
                     ))
              ],
            )
          ],
        ),

      )
    );
  }
  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;

 void  loginAndAuthenticateUser(BuildContext context)async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
      builder: (BuildContext context)
      {
      return  ProgressDialog(message:'Authenticating, Please wait...',
      );
      }
               );

    final User firebaseUser=(await _firebaseAuth
        .signInWithEmailAndPassword(email: emailTextEditingController.text,
        password: passwordTextEditingController.text).catchError((errorMsg)
    {
      Navigator.pop(context); // this is for Stopped progreesDialog
      displayToastMessage('Error: ' + errorMsg.toString(), context);
    })
    ).user;

    if(firebaseUser !=null)
        {
          usersRef.child(firebaseUser.uid).once().then( (DataSnapshot snap)
          {
            if(snap.value != null ){
              Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
              displayToastMessage("you are logged-in now", context);
          }else
            {
              Navigator.pop(context); // this is for Stopped progreesDialog
              _firebaseAuth.signOut();
              displayToastMessage("No record exists for this user,please create a new account",
                  context);
            }});
    }else
    {
      //error occured - display error
      Navigator.pop(context); // this is for Stopped progreesDialog
      displayToastMessage("Error occured can\'t be sigin in", context);
    }
  }
  }
