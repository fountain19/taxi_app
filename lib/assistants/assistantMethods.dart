
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/assistants/requestAssintants.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/dataHandler/appData.dart';
import 'package:taxi_app/models/address.dart';
import 'package:taxi_app/models/allUser.dart';
import 'package:taxi_app/models/directDetails.dart';
import 'package:http/http.dart' as http;

class AssistantMethods{
  static Future<String> searchCoordinateAddress(Position position,context) async
  {
    String placeAddress='';
    String st1,st2,st3,st4;
    String url='https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey';
    var response= await RequestAssistant.getRequest(url);
    if(response != 'failed')
      {
       // placeAddress=response['results'][0]['formatted_address'];
        st1=response['results'][0]['address_components'][3]['long_name'];
         st2=response['results'][0]['address_components'][4]['long_name'];
        st3=response['results'][0]['address_components'][5]['long_name'];
        st4=response['results'][0]['address_components'][6]['long_name'];

        placeAddress= st1 + ', ' +st2 + ', '+ st3 + ', '+ st4;


        Address userPickUpAddress= Address();
        userPickUpAddress.latitude=position.latitude;
        userPickUpAddress.longitude=position.longitude;
        userPickUpAddress.placeName=placeAddress;

        Provider.of<AppData>(context,listen: false).updatePickUpLocationAddress(userPickUpAddress);
      }
    return placeAddress;
  }
  static Future<DirectionDetails> obtainPlaceDirectionDetails(LatLng initialPosition,LatLng finalPosition)async
  {
       String directionUrl='https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey';
       var res=await RequestAssistant.getRequest(directionUrl);

       if(res == 'failed')
         {return null;}
       DirectionDetails directionDetails=DirectionDetails();
       directionDetails.encodedPoints=res['routes'][0]['overview_polyline']['points'];
       directionDetails.distanceText= res['routes'][0]['legs'][0]['distance']['text'];
       directionDetails.distanceValue=res['routes'][0]['legs'][0]['distance']['value'];
       directionDetails.durationText= res['routes'][0]['legs'][0]['duration']['text'];
       directionDetails.durationValue=res['routes'][0]['legs'][0]['duration']['value'];
       return directionDetails;
  }
  static int calculateFares(DirectionDetails directionDetails)
  {
    // calculate in $
     double timeTraveledFare= (directionDetails.durationValue/60)*0.20;
     double distanceTraveledFare= (directionDetails.distanceValue/1000)*0.20;
     double totalFareAmount= timeTraveledFare+distanceTraveledFare;

     // local currency
    // in turkey 1$ = 7.5
    // double totalLocalAmount= totalFareAmount*7.5;
    return totalFareAmount.truncate();
  }
   static void getCurrentOnlineUserInfo() async
   {
     fireBaseUser = await FirebaseAuth.instance.currentUser;
     String userId= fireBaseUser.uid;
     DatabaseReference reference = FirebaseDatabase.instance.reference().child('users').child(userId);
     reference.once().then((DataSnapshot dataSnapShot)
     {
       if(dataSnapShot.value != null)
         {
           userCurrentInfo= Users.fromSnapshot(dataSnapShot);
         }
     });
   }
   static double createRandomNumber(int num)
   {
     var random =Random();
     int radNumber= random.nextInt(num);
        return radNumber.toDouble();
   }
   static sendNotificationToDriver(String token,context,String ride_request_id)async
   {
     var destination = Provider.of<AppData>(context,listen: false).dropOffLocation;
     Map<String,String> headerMap=
         {
           'Content-Type': 'application/json',
           'Authorization': serverToken,
         };
     Map notificationMap=
     {
       'body': 'DropOff address : ${destination.placeName}',
       'title': 'New ride request'
     };
       Map dataMap =
           {
       'click_action': 'FLUTTER_NOTIFICATION_CLICK',
       'id': '1',
       'status': 'done',
       'ride_request_id': ride_request_id,
           };
       Map sendNotificationMap =
           {
             'notification':notificationMap,
             'data' : dataMap,
             'priority': 'high',
             'to': token
           };
       var res = await http.post(
           'https://fcm.googleapis.com/fcm/send',
       headers: headerMap,
         body: jsonEncode(sendNotificationMap)
       );
   }
}