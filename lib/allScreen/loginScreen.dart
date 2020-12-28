
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
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
                        onPressed: (){},
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
                     onPressed: (){},
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
}
