
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:taxi_app/configMaps.dart';

class RatingScreen extends StatefulWidget {
  final String driverid;
  RatingScreen({this.driverid});

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(5.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22.0,),
              Text('Rate this driver',style: TextStyle(fontSize: 20,color: Colors.black54),),
              SizedBox(height: 22.0,),
              Divider(height: 2.0,thickness: 2.0,),
              SizedBox(height: 16.0,),
              SmoothStarRating(
                rating: starCounter,
                color: Colors.green,
                allowHalfRating: false,// display or not the number of rating
                starCount: 5,
                size: 45,
                onRated: (value) {
                  starCounter=value;
                  if(starCounter==1)
                  {
                    setState(() {
                      title='Very bad';
                    });
                  }
                  else  if(starCounter==2)
                  {
                    setState(() {
                      title=' Bad';
                    });
                  }
                  else  if(starCounter==3)
                  {
                    setState(() {
                      title=' Good';
                    });
                  }
                  else  if(starCounter==4)
                  {
                    setState(() {
                      title=' Very good';
                    });
                  }
                  else  if(starCounter==5)
                  {
                    setState(() {
                      title=' Excellent';
                    });
                  }
                },
              ),
              SizedBox(height: 14.0,),
              Text(title,style:TextStyle(color: Colors.green,fontSize: 55.0,fontFamily: 'Signatra') ,),
              SizedBox(height: 16.0,),
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: 16.0),
                child: RaisedButton(
                  onPressed: ()
                  {
                    DatabaseReference driverRatingRef = FirebaseDatabase.instance.reference().
                    child('drivers').child(widget.driverid).child('ratings');
                    driverRatingRef.once().then((DataSnapshot snap)  {
                      if(snap.value != null)
                        {
                           double oldRatings = double.parse(snap.value.toString());
                           double addRatings = oldRatings +starCounter;
                           double averageRatings = addRatings/2;
                           driverRatingRef.set(averageRatings.toString());
                        }
                      else{
                        driverRatingRef.set(starCounter.toString());
                      }
                    });
                    Navigator.pop(context);
                  },
                  color: Colors.green[500],
                  child: Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Submit',style: TextStyle(color: Colors.black,fontSize: 20.0,fontWeight: FontWeight.bold),),

                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.0,)
            ],
          ),
        ),
      ),
    );
  }
}
