import 'package:flutter/cupertino.dart';
import 'package:taxi_app/models/address.dart';


class AppData extends ChangeNotifier
{
   Address pickUpLocation ;
   void updatePickUpLocationAddress(Address pickUpAddress)
   {
     pickUpLocation=pickUpAddress;
     notifyListeners();
   }
}