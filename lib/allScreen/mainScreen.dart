import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/allWidgets/divider.dart';
import 'package:taxi_app/assistants/assistantMethods.dart';
import 'package:taxi_app/dataHandler/appData.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen='mainScreen';
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  GlobalKey<ScaffoldState> scaffoldkey= GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;
  Position currentPosition;
  var geoLocator=Geolocator();
  double bottomPaddingOfMap=0;


  void locatePosition()async
  {
    Position position=await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition=position;
    LatLng latLngPosition=LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition= CameraPosition(target: latLngPosition,zoom: 14);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    String address= await AssistantMethods.searchCoordinateAddress(position,context);
    print('this is your address :' + address);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldkey,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black
        ),
        backgroundColor: Colors.yellow,
        title: Text('Main Screen',style: TextStyle(color: Colors.black,
        fontWeight: FontWeight.bold,
        ),),
        centerTitle: true,
      ),
      drawer: Container(
        width: 255,
        color: Colors.white,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Image.asset('images/user_icon.png',height: 65,width: 65,),
                      SizedBox(width:16.0,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Profile Name',style: TextStyle(
                              fontSize:16.0,fontFamily: 'bolt-regular'),),
                          SizedBox(height: 6.0,),
                          Text('Visit profile'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0,),
              // drawer body controller
              ListTile(
                leading: Icon(Icons.history),
                title: Text('History',style: TextStyle(fontSize: 15),),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Visit profile',style: TextStyle(fontSize: 15),),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About',style: TextStyle(fontSize: 15),),
              ),
            ],
          ),
        ),
      ),
      body:Stack(
    children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (GoogleMapController controller)
            {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController=controller;
            setState(() {
              bottomPaddingOfMap=300.0;
            });

            locatePosition();
            },
            ),
    // HamburgerButton for Drawer
        Positioned(
          top: 45.0,left: 22.0,
          child: GestureDetector(
            onTap: (){
            scaffoldkey.currentState.openDrawer();
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black,
                        blurRadius: 6.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7)
                    )
                  ]
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.menu,color: Colors.black,),
                radius: 20.0,
              ),
            ),
          ),
        ),
    Positioned(
    left: 0.0,right: 0.0,bottom: 0.0,
    child: Container(
       height: 300.0,
    decoration: BoxDecoration(
       color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(18.0),topRight: Radius.circular(18.0),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        blurRadius: 16.0,
        spreadRadius: 0.5,
        offset: Offset(0.7,0.7)
      )
    ]
    ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6.0,),
            Text('Hi there ',style:TextStyle(fontSize: 12.0),),
            Text('Where to ?',style: TextStyle(fontSize:20.0,fontFamily: 'bolt-regular'),),
            SizedBox(height: 20.0,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7)
                    )
                  ]
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.search,color: Colors.blueAccent,),
                    SizedBox(width: 10.0,),
                    Text('Search drop off')
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.0,),
            Row(
              children: [
                Icon(Icons.home,color: Colors.grey,),
                SizedBox(width: 12.0,),
                Column(
                  children: [
                    Text(
                      Provider.of<AppData>(context).pickUpLocation!=null?
                      Provider.of<AppData>(context).pickUpLocation.placeName:
                      'Add home'
                    ),
                    SizedBox(height: 4.0,),
                    Text('Your living home address',
                      style: TextStyle(
                          fontSize:12.0,color: Colors.black54),),
                  ],
                )

              ],
            ),
            SizedBox(height: 10.0,),
            DividerWidget(),
            SizedBox(height: 16.0,),
            Row(
              children: [
                Icon(Icons.work,color: Colors.grey,),
                SizedBox(width: 12.0,),
                Column(
                  children: [
                    Text('Add work'),
                    SizedBox(height: 4.0,),
                    Text('Your office address',
                      style: TextStyle(
                          fontSize:12.0,color: Colors.black54),),
                  ],
                )

              ],
            )
          ],
        ),
      ),
    ),
    )

    ],

    ));
  }
}
