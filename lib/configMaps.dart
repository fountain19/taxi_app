import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxi_app/models/allUser.dart';

String mapKey='AIzaSyBS90FJuaE8n8oklnjTt9MOvZMELlDs_eQ';
User fireBaseUser;
Users userCurrentInfo;
int driverRequestTimeOut = 40;
String statusRide='';
String rideStatus='Driver is coming';
String carDetailsDriver='';
String driverName='';
String driverPhone='';
double starCounter=0.0;
String title='';
String carRideType='';
String serverToken = 'key=	AAAAiSlswpc:APA91bEU0gzW5rYcROfTXduvRTt5PGG3rqu-EA3S6YU8ffScXUMfyBW0kf_G0MtQzxfMXjyOPs9CJmmpmZzyzHXgEd5xm87_6nTpf3MHY0z7EajNBCXkbqTqojAeXLSXNQtqcxRKFJbX';