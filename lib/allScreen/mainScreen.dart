import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/allScreen/loginScreen.dart';
import 'package:taxi_app/allScreen/searchScreen.dart';
import 'package:taxi_app/allWidgets/divider.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/assistants/assistantMethods.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/dataHandler/appData.dart';
import 'package:taxi_app/models/directDetails.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen='mainScreen';
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {

  GlobalKey<ScaffoldState> scaffoldkey= GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;
  Position currentPosition;
  var geoLocator=Geolocator();
  double bottomPaddingOfMap=0;
  // create polyline supplies
  List<LatLng> pLineCoordinates=[];
  Set<Polyline> polyLineSet={};

  Set<Marker> markersSet={};
  Set<Circle> circlesSet={};
  DirectionDetails tripDirectionDetails;
  double rideDetailsContainerHeight=0;
  double searchContainerHeight=300.0;
  double requestRideContainerHeight=0;

  bool drawerOpen= true;
  DatabaseReference rideRequestRef;

  @override
  void initState() {
     super.initState();
     AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest()
  {
    rideRequestRef = FirebaseDatabase.instance.reference().child('Ride Request').push();
    var pickUp= Provider.of<AppData>(context,listen: false).pickUpLocation;
    var dropOff= Provider.of<AppData>(context,listen: false).dropOffLocation;
    Map pickULocMap=
    {
    'longitude':pickUp.longitude.toString(),
    'latitude':pickUp.latitude.toString()
    };
    Map dropOffLocMap=
    {
    'longitude':dropOff.longitude.toString(),
    'latitude':dropOff.latitude.toString()
    };
    Map rideInfoMap=
        {
          'driver_id':"waiting",
          'payment_method':'cash',
          'pickUp':pickULocMap,
          'dropOff':dropOffLocMap,
          'created_at':DateTime.now().toString(),
          'rider_name':userCurrentInfo.name,
          'rider_phone':userCurrentInfo.phone,
          'pickUp_address':pickUp.placeName,
          'dropOff_address':dropOff.placeName
        };
    rideRequestRef.set(rideInfoMap);
  }

  void cancelRideRequest()
  {
    rideRequestRef.remove();
  }

  void displayRequestRideContainer()
  {
    setState(() {
      requestRideContainerHeight=250.0;
      rideDetailsContainerHeight=0;
      bottomPaddingOfMap=230.0;
      drawerOpen=true;
    });
    saveRideRequest();
  }

  resetApp()
  {
    setState(() {
      drawerOpen=true;
      searchContainerHeight=300.0;
      rideDetailsContainerHeight=0;
      bottomPaddingOfMap=230.0;
       requestRideContainerHeight=0;
       polyLineSet.clear();
       markersSet.clear();
       circlesSet.clear();
       pLineCoordinates.clear();
    });
    locatePosition();
  }

 void displayRideDetailsContainer()async
  {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight=0;
      rideDetailsContainerHeight=240.0;
      bottomPaddingOfMap=230.0;
      drawerOpen=false;
    });
  }

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
              GestureDetector(
                onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.close),
                  title: Text('Sign out ',style: TextStyle(fontSize: 15),),
                ),
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
            polylines: polyLineSet,
            markers: markersSet,
            circles: circlesSet,
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
          top: 38.0,left: 22.0,
          child: GestureDetector(
            onTap: (){
              if(drawerOpen)
                {
                  scaffoldkey.currentState.openDrawer();
                }
            else {resetApp();}
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
                child: Icon((drawerOpen)?Icons.menu:Icons.close,color: Colors.black,),
                radius: 20.0,
              ),
            ),
          ),
        ),
    Positioned(
    left: 0.0,right: 0.0,bottom: 0.0,
    child: AnimatedSize(
      vsync: this,
      curve: Curves.bounceIn,
      duration: Duration(milliseconds: 160),
      child: Container(
         height: searchContainerHeight,
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


              GestureDetector(
                onTap: ()async{
                var res = await Navigator.push(context, MaterialPageRoute(builder: (context)=>SearchScreen()));
                if(res =='obtain direction')
                  {
                 displayRideDetailsContainer();
                  }
                },
                child: Container(
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
    ),
    ),
    Positioned(
    left: 0.0,right: 0.0,bottom: 0.0,
    child: AnimatedSize (
      vsync: this,
      curve: Curves.bounceIn,
      duration: Duration(milliseconds: 160),
      child: Container(
      height: rideDetailsContainerHeight,
      decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
      topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0),
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
          padding:  EdgeInsets.symmetric(vertical: 17.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.tealAccent[100],
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(

                    children: [
                      Image.asset('images/taxi.png',height: 70,width: 80.0,),
                      SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Car',style: TextStyle(fontFamily: 'bolt-regular',fontSize: 18.0),),
                          Text((tripDirectionDetails != null)?tripDirectionDetails.distanceText:'',style: TextStyle(color: Colors.grey,fontSize: 18.0),),
                        ],
                      ),
                      Expanded(child: Container()),
                      Text((tripDirectionDetails != null)?'\$${AssistantMethods.calculateFares(tripDirectionDetails)}':'',style: TextStyle(fontFamily: 'bolt-regular',),),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.0,),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0,),
                child: Row(
                  children: [
                   Icon(FontAwesomeIcons.moneyCheckAlt,size: 18.0,color: Colors.black54,),
                    SizedBox(width: 16.0,),
                    Text('Cash'),
                    SizedBox(width: 6.0,),
                    Icon(Icons.keyboard_arrow_down,color: Colors.black54,size: 16.0,),
                  ],
                ),
              ),
              SizedBox(height: 24.0,),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: RaisedButton(
                onPressed: (){displayRequestRideContainer();},
                color: Theme.of(context).accentColor,
                child: Padding(
                  padding: EdgeInsets.all(17.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Request',style: TextStyle(color: Colors.white,fontSize: 20.0,fontWeight: FontWeight.bold),),
                      Icon(FontAwesomeIcons.taxi,color: Colors.white,size: 26.0,)
                    ],
                  ),
                ),
              )
                ,)
            ],
          ),
        ),
      ),
    ),
    ),
                    Positioned(
                      bottom: 0.0,left: 0.0,right: 0.0,
                      child: Container(
                      height: requestRideContainerHeight,
                      decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0),
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
                        child:Padding(
                          padding:  EdgeInsets.all(30.0),
                          child: Column(
                            children: [
                              SizedBox(height: 12.0,),
                                SizedBox(
                                width: double.infinity,
                                child: ColorizeAnimatedTextKit(
                                onTap: () {
                                print("Tap Event");
                                },
                                text: [
                                "Requesting a ride...",
                                "Please wait...",
                                "finding a driver ...",
                                ],
                                textStyle: TextStyle(
                                fontSize: 55.0,
                                fontFamily: "Signatra"
                                ),
                                colors: [
                                  Colors.green,
                                  Colors.purple,
                                Colors.pink,
                                Colors.blue,
                                Colors.yellow,
                                Colors.red,
                                ],
                                textAlign: TextAlign.center,
                                ),
                                ),
                              SizedBox(height: 22.0,),
                              GestureDetector(
                                onTap: (){
                                  cancelRideRequest();
                                  resetApp();
                                },
                                child: Container(
                                  height: 60.0,width: 60.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26.0),
                                    border: Border.all(width: 2.0,color: Colors.grey[300]),
                                  ),
                                  child: Icon(Icons.close,size: 26.0,),
                                ),
                              ),
                              SizedBox(height: 10.0,),
                              Container(
                                width: double.infinity,
                                child: Text(
                                  'Cancel ride',style: TextStyle(fontSize: 12.0,
                                fontWeight: FontWeight.bold),textAlign: TextAlign.center
                                ),
                              )
                            ],
                          ),
                        ) ,
                      ),
                    ),
    ],

    ));
  }
  Future<void> getPlaceDirection()async
  {
    var initialPos= Provider.of<AppData>(context,listen: false).pickUpLocation;
    var finalPos= Provider.of<AppData>(context,listen: false).dropOffLocation;
    var pickUpLatLng= LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng= LatLng(finalPos.latitude, finalPos.longitude);
    showDialog(
        context: context,
        builder: (BuildContext context )=>ProgressDialog(message: 'Please wait...',)
    );
    var details= await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails=details;
    });
    Navigator.pop(context);
    print('this is encoded points :::::');
    print(details.encodedPoints);

    PolylinePoints polylinePoints=PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult=polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();
    if(decodedPolyLinePointsResult.isNotEmpty)
      {
        decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng)
        {
          pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));

        });
      }
    polyLineSet.clear();

    setState(() {
      Polyline polyline=Polyline(
          polylineId: PolylineId('PolyLineId'),
            color: Colors.pink,
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true
      );
      polyLineSet.add(polyline);
    });
    // control by site for both pickup and dropdown
    LatLngBounds latLngBounds;
    if(pickUpLatLng.latitude>dropOffLatLng.latitude&&pickUpLatLng.longitude>dropOffLatLng.longitude)
      {
        latLngBounds=LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
      }
    else if(pickUpLatLng.latitude>dropOffLatLng.latitude)
    {
      latLngBounds=LatLngBounds(southwest: LatLng(dropOffLatLng.latitude,pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude,dropOffLatLng.longitude),);
    }
    else if(pickUpLatLng.longitude>dropOffLatLng.longitude)
    {
      latLngBounds=LatLngBounds(southwest: LatLng(pickUpLatLng.latitude,dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude,pickUpLatLng.longitude),);
    }
    else
      {
        latLngBounds=LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
      }
    newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker= Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(title: initialPos.placeName,snippet: 'My Location'),
      position: pickUpLatLng,
      markerId: MarkerId('pickUpId')    );
    Marker dropOffLocMarker= Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed ),
        infoWindow: InfoWindow(title: finalPos.placeName,snippet: 'DropOff location'),
        position: dropOffLatLng,
        markerId: MarkerId('dropOffId')    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle=Circle(
        circleId:CircleId('pickUpId'),
         fillColor: Colors.blueAccent ,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent
    );
    Circle dropOffLocCircle=Circle(
        circleId:CircleId('dropOffId'),
        fillColor: Colors.deepPurple ,
        center: dropOffLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }
}
