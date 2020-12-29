
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:taxi_app/allScreen/loginScreen.dart';
import 'package:taxi_app/allScreen/mainScreen.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/main.dart';



class RegisterationScreen extends StatelessWidget {

  static const String idScreen='register';
  TextEditingController nameTextEditingController=TextEditingController();
  TextEditingController emailTextEditingController=TextEditingController();
  TextEditingController passwordTextEditingController=TextEditingController();
  TextEditingController phoneTextEditingController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body:SafeArea(
          child:  ListView(
            children: [
              Column(
                children: [
                  SizedBox(height: 20.0,),
                  Image(
                    image: AssetImage('images/logo.png'),
                    width: 390.0,height: 250.0,
                    alignment: Alignment.center,
                  ),
                  SizedBox(height: 1.0,),
                  Text('Register as a rider',style: TextStyle(fontSize: 24.0,
                      fontFamily: 'bolt-regular',fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding:EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        SizedBox(height: 1.0,),
                        TextField(
                          controller: nameTextEditingController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Name',
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
                        controller: phoneTextEditingController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone',
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
                            if(nameTextEditingController.text.length< 3)
                              {
                                displayToastMessage('Name must be at least 3 characters', context);
                              }
                            else if(!emailTextEditingController.text.contains('@'))
                              {
                                displayToastMessage('Email address is not valid', context);
                              }
                            else if(passwordTextEditingController.text.length< 6)
                            {
                              displayToastMessage('password must be at least 6 characters', context);
                            }
                            else if(phoneTextEditingController.text.isEmpty)
                            {
                              displayToastMessage('Phone number is necessary', context);
                            }
                            else
                              {
                                registerNewUser(context);
                              }
                          },
                          color: Colors.yellow,
                          textColor: Colors.black,
                          child: Container(
                            height: 50.0,
                            child: Center(
                              child: Text(
                                'Create  account',style: TextStyle(
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
                        Navigator.pushNamedAndRemoveUntil(context,LoginScreen.idScreen, (route) => false);
                      },
                      child: Text(
                        'Already have an account ? Login here',
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
 void registerNewUser(BuildContext context)async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context)
        {
          return  ProgressDialog(message:'Registering, Please wait...',);
        }
    );
  final User firebaseUser=(await _firebaseAuth
      .createUserWithEmailAndPassword(email: emailTextEditingController.text,
      password: passwordTextEditingController.text).catchError((errorMsg)
  {
    Navigator.pop(context); // this is for Stopped progreesDialog
    displayToastMessage('Error: ' + errorMsg.toString(), context);
  })
  ).user;
  if(firebaseUser !=null) // user created
    {
      //save user info to database

    Map userDataMap =
        {
          'name':nameTextEditingController.text.trim(),
          'email':emailTextEditingController.text.trim(),
          'phone':phoneTextEditingController.text.trim()
        };

    usersRef.child(firebaseUser.uid).set(userDataMap);
    displayToastMessage("Congratulation, your account has been created", context);
    Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);

  }else
    {
      //error occured - display error
      Navigator.pop(context); // this is for Stopped progreesDialog
      displayToastMessage("New user account has not been created", context);
    }
  }
}

displayToastMessage(String text,BuildContext context)
{
  Fluttertoast.showToast(msg: text);
}