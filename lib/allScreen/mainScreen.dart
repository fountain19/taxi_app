import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/allScreen/loginScreen.dart';
import 'package:taxi_app/allScreen/ratingScreen.dart';
import 'package:taxi_app/allScreen/searchScreen.dart';
import 'package:taxi_app/allWidgets/collectFareDailog.dart';
import 'package:taxi_app/allWidgets/divider.dart';
import 'package:taxi_app/allWidgets/noDriverAvaiableDailog.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/assistants/assistantMethods.dart';
import 'package:taxi_app/assistants/geoFireAssistant.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/dataHandler/appData.dart';
import 'package:taxi_app/main.dart';
import 'package:taxi_app/models/directDetails.dart';
import 'package:taxi_app/models/nearbyAvaibelDrivers.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen='mainScreen';
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {

  GlobalKey<ScaffoldState> scaffoldkey = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;
  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  // create polyline supplies
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  DirectionDetails tripDirectionDetails;
  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double requestRideContainerHeight = 0;
  double driverDetailsContainerHeight=0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeyLoaded=false;
  DatabaseReference rideRequestRef;
  BitmapDescriptor nearByIcon;
  List<NearbyAvailableDrivers> availableDrivers;
String state ='normal';
StreamSubscription<Event> rideStreamSubscription;
bool isRequestingPositionDetails=false;

  @override
  void initState() {
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child('rideRequest').push();
    var pickUp = Provider
        .of<AppData>(context, listen: false)
        .pickUpLocation;
    var dropOff = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;
    Map pickULocMap =
    {
      'longitude': pickUp.longitude.toString(),
      'latitude': pickUp.latitude.toString()
    };
    Map dropOffLocMap =
    {
      'longitude': dropOff.longitude.toString(),
      'latitude': dropOff.latitude.toString()
    };
    Map rideInfoMap =
    {
      'driver_id': "waiting",
      'payment_method': 'cash',
      'pickUp': pickULocMap,
      'dropOff': dropOffLocMap,
      'created_at': DateTime.now().toString(),
      'rider_name': userCurrentInfo.name,
      'rider_phone': userCurrentInfo.phone,
      'pickUp_address': pickUp.placeName,
      'dropOff_address': dropOff.placeName
    };
    rideRequestRef.set(rideInfoMap);
    rideStreamSubscription=rideRequestRef.onValue.listen((event) async{
      if(event.snapshot.value==null)
        {
          return;
        }
      if(event.snapshot.value['carDetails'] != null)
      {
        setState(() {
          carDetailsDriver =event.snapshot.value['carDetails'].toString();
        });
      }
      if(event.snapshot.value['driverName'] != null)
      {
        setState(() {
          driverName =event.snapshot.value['driverName'].toString();
        });
      }
      if(event.snapshot.value['driverLocation'] != null)
      {
        double  driverLat =double.parse(event.snapshot.value['driverLocation']['latitude'].toString());
        double  driverLng =double.parse(event.snapshot.value['driverLocation']['latitude'].toString());
        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);
        if(statusRide =='accepted')
          {
            updateRideTimeToPickupLoc(driverCurrentLocation);
          }else if(statusRide == 'onRide')
            {
              updateRideTimeToDropOffLoc(driverCurrentLocation);
            }
        else if(statusRide == 'arrived')
        {
          setState(() {
            rideStatus='Driver has arrived';
          });
        }

      }
      if(event.snapshot.value['driverPhone'] != null)
      {
        setState(() {
          driverPhone =event.snapshot.value['driverPhone'].toString();
        });
      }
      if(event.snapshot.value['status'] != null)
        {
          statusRide =event.snapshot.value['status'].toString();
        }
      if(statusRide == 'accepted')
        {
          displayDriverDetailsContainer();
          Geofire.stopListener();
          deleteGeofileMarkers();
        }
      if(statusRide == 'ended')
      {
        if(event.snapshot.value['fares'] != null)
          {
            int fare= int.parse(event.snapshot.value['fares'].toString());
            var res = await showDialog(
                context: context,
            barrierDismissible: false,
              builder: (BuildContext context) => CollectFareDialog(
                paymentMethod: 'Cash',fareAmount: fare,
              )
            );
            String driverid='';
            if(res == 'close')
              {
                if(event.snapshot.value['driverId']!=null)
                {
                  driverid=event.snapshot.value['driverId'].toString();
                }
                Navigator.push(context, MaterialPageRoute(builder: (context)=>
                RatingScreen(driverid:driverid)));
                rideRequestRef.onDisconnect();
                rideRequestRef = null;
                rideStreamSubscription.cancel();
                rideStreamSubscription = null;
                resetApp();
              }
          }
      }
    });
  }

  void deleteGeofileMarkers()
  {
    setState(() {
      markersSet.removeWhere((element) => element.markerId.value.contains('driver'));
    });
  }

  void updateRideTimeToPickupLoc(LatLng driverCurrentLocation)async
  {
   if(isRequestingPositionDetails == false)
     {
       isRequestingPositionDetails =true;
       var positionUserLatLng =LatLng(currentPosition.latitude,currentPosition.longitude);
       var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, positionUserLatLng);
       if(details == null )
       {
         return;
       }
       setState(() {
         rideStatus = 'Driver is coming -' + details.durationText;
       });
       isRequestingPositionDetails = false;
     }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation)async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails =true;
      var dropOff=Provider.of<AppData>(context,listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff.latitude,dropOff.longitude);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, dropOffUserLatLng);
      if(details == null )
      {
        return;
      }
      setState(() {
        rideStatus = 'Going to destination-'+details.durationText;
      });
      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
    setState(() {
      state ='normal';
    });
  }

  void displayDriverDetailsContainer()
  {
    setState(() {
      requestRideContainerHeight = 0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 290.0;
      driverDetailsContainerHeight=320.0;
    });
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });
    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      requestRideContainerHeight = 0;
      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
      statusRide='';
      driverName='';
      driverPhone='';
      carDetailsDriver='';
      rideStatus='Driver is coming';
      driverDetailsContainerHeight=0.0;

    });
    locatePosition();
  }

  void displayRideDetailsContainer() async
  {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async
  {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
    LatLng latLngPosition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition = CameraPosition(
        target: latLngPosition, zoom: 14);
    newGoogleMapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition));
    String address = await AssistantMethods.searchCoordinateAddress(
        position, context);
    print('this is your address :' + address);
    initGeoFireListener();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
        key: scaffoldkey,
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
                        Image.asset(
                          'images/user_icon.png', height: 65, width: 65,),
                        SizedBox(width: 16.0,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Profile Name', style: TextStyle(
                                fontSize: 16.0, fontFamily: 'bolt-regular'),),
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
                  title: Text('History', style: TextStyle(fontSize: 15),),
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Visit profile', style: TextStyle(fontSize: 15),),
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About', style: TextStyle(fontSize: 15),),
                ),
                GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, LoginScreen.idScreen, (route) => false);
                  },
                  child: ListTile(
                    leading: Icon(Icons.close),
                    title: Text('Sign out ', style: TextStyle(fontSize: 15),),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
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
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                setState(() {
                  bottomPaddingOfMap = 300.0;
                });

                locatePosition();
              },
            ),
            // HamburgerButton for Drawer
            Positioned(
              top: 38.0, left: 22.0,
              child: GestureDetector(
                onTap: () {
                  if (drawerOpen) {
                    scaffoldkey.currentState.openDrawer();
                  }
                  else {
                    resetApp();
                  }
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
                            offset: Offset(0.7, 0.7)
                        )
                      ]
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon((drawerOpen) ? Icons.menu : Icons.close,
                      color: Colors.black,),
                    radius: 20.0,
                  ),
                ),
              ),
            ),
            //search Ui
            Positioned(
              left: 0.0, right: 0.0, bottom: 0.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 16.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7)
                        )
                      ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6.0,),
                        Text('Hi there ', style: TextStyle(fontSize: 12.0),),
                        Text('Where to ?', style: TextStyle(
                            fontSize: 20.0, fontFamily: 'bolt-regular'),),
                        SizedBox(height: 20.0,),


                        GestureDetector(
                          onTap: () async {
                            var res = await Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (context) => SearchScreen()));
                            if (res == 'obtain direction') {
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
                                      offset: Offset(0.7, 0.7)
                                  )
                                ]
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.blueAccent,),
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
                            Icon(Icons.home, color: Colors.grey,),
                            SizedBox(width: 12.0,),
                            Column(
                              children: [
                                Text(
                                    Provider
                                        .of<AppData>(context)
                                        .pickUpLocation != null ?
                                    Provider
                                        .of<AppData>(context)
                                        .pickUpLocation
                                        .placeName :
                                    'Add home'
                                ),
                                SizedBox(height: 4.0,),
                                Text('Your living home address',
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.black54),),
                              ],
                            )

                          ],
                        ),
                        SizedBox(height: 10.0,),
                        DividerWidget(),
                        SizedBox(height: 16.0,),
                        Row(
                          children: [
                            Icon(Icons.work, color: Colors.grey,),
                            SizedBox(width: 12.0,),
                            Column(
                              children: [
                                Text('Add work'),
                                SizedBox(height: 4.0,),
                                Text('Your office address',
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.black54),),
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
            //Ride details ui
            Positioned(
              left: 0.0, right: 0.0, bottom: 0.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: Duration(milliseconds: 160),
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 16.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7)
                        )
                      ]
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 17.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.tealAccent[100],
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(

                              children: [
                                Image.asset(
                                  'images/taxi.png', height: 70, width: 80.0,),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Car', style: TextStyle(
                                        fontFamily: 'bolt-regular',
                                        fontSize: 18.0),),
                                    Text((tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : '', style: TextStyle(
                                        color: Colors.grey, fontSize: 18.0),),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text((tripDirectionDetails != null)
                                    ? '\$${AssistantMethods.calculateFares(
                                    tripDirectionDetails)}'
                                    : '', style: TextStyle(
                                  fontFamily: 'bolt-regular',),),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.0,),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0,),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.moneyCheckAlt, size: 18.0,
                                color: Colors.black54,),
                              SizedBox(width: 16.0,),
                              Text('Cash'),
                              SizedBox(width: 6.0,),
                              Icon(Icons.keyboard_arrow_down,
                                color: Colors.black54, size: 16.0,),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.0,),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: RaisedButton(
                            onPressed: () {
                              setState(() {
                                state = 'requesting';
                              });
                              displayRequestRideContainer();
                              availableDrivers=GeoFireAssistant.nearbyAvailableDriversList;
                              searchNearestDrivers();
                            },
                            color: Theme
                                .of(context)
                                .accentColor,
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text('Request', style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold),),
                                  Icon(
                                    FontAwesomeIcons.taxi, color: Colors.white,
                                    size: 26.0,)
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
            // cancel ui
            Positioned(
              bottom: 0.0, left: 0.0, right: 0.0,
              child: Container(
                height: requestRideContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7)
                      )
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.all(30.0),
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
                        onTap: () {
                          cancelRideRequest();
                          resetApp();
                        },
                        child: Container(
                          height: 60.0, width: 60.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26.0),
                            border: Border.all(width: 2.0,
                                color: Colors.grey[300]),
                          ),
                          child: Icon(Icons.close, size: 26.0,),
                        ),
                      ),
                      SizedBox(height: 10.0,),
                      Container(
                        width: double.infinity,
                        child: Text(
                            'Cancel ride', style: TextStyle(fontSize: 12.0,
                            fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            // display assigned driver info
            Positioned(
              bottom: 0.0, left: 0.0, right: 0.0,
              child: Container(
                height: driverDetailsContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7)
                      )
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0,vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                   SizedBox(height: 6.0,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                             rideStatus,textAlign: TextAlign.center,style: TextStyle(
                              fontSize: 20.0,fontFamily: 'bolt-regular'
                            ),
                            ),
                        ],
                      ),
                      SizedBox(height: 22.0,),
                      Divider(height: 2.0,thickness: 2.0,),
                      SizedBox(height: 22.0,),
                      Text(carDetailsDriver,style:TextStyle(color: Colors.grey),),
                      Text(driverName,style: TextStyle(fontSize: 20.0),),
                      SizedBox(height: 22.0,),
                      Divider(height: 2.0,thickness: 2.0,),
                      SizedBox(height: 22.0,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                         // call button
                          Padding(
                              padding:EdgeInsets.symmetric(horizontal: 20.0),
                          child: RaisedButton(
                            onPressed: ()async{
                              launch(('tel://${driverPhone}'));
                            },
                            color: Colors.pink,
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('Call driver',style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color: Colors.black),),
                                  Icon(Icons.call,color: Colors.black,size: 26.0,)
                                ],
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

        ));
  }

  Future<void> getPlaceDirection() async
  {
    var initialPos = Provider
        .of<AppData>(context, listen: false)
        .pickUpLocation;
    var finalPos = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;
    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: 'Please wait...',)
    );
    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });
    Navigator.pop(context);
    print('this is encoded points :::::');
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult = polylinePoints
        .decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();
    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(
            LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
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
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    }
    else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
        northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),);
    }
    else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
        northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),);
    }
    else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }
    newGoogleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
            title: initialPos.placeName, snippet: 'My Location'),
        position: pickUpLatLng,
        markerId: MarkerId('pickUpId'));
    Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
            title: finalPos.placeName, snippet: 'DropOff location'),
        position: dropOffLatLng,
        markerId: MarkerId('dropOffId'));

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
        circleId: CircleId('pickUpId'),
        fillColor: Colors.blueAccent,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent
    );
    Circle dropOffLocCircle = Circle(
        circleId: CircleId('dropOffId'),
        fillColor: Colors.deepPurple,
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

  void initGeoFireListener()
{
  Geofire.initialize('availableDrivers');
    //comment
    Geofire.queryAtLocation(currentPosition.latitude , currentPosition.longitude, 15).listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:

            NearbyAvailableDrivers nearbyAvailableDrivers=NearbyAvailableDrivers();
            nearbyAvailableDrivers.key=map['key'];
            nearbyAvailableDrivers.latitude=map['latitude'];
            nearbyAvailableDrivers.longitude=map['longitude'];
              GeoFireAssistant.nearbyAvailableDriversList.add(nearbyAvailableDrivers);
              if(nearbyAvailableDriverKeyLoaded==true)
                {
                  updateAvailableDriversOnMap();
                }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers=NearbyAvailableDrivers();
            nearbyAvailableDrivers.key=map['key'];
            nearbyAvailableDrivers.latitude=map['latitude'];
            nearbyAvailableDrivers.longitude=map['longitude'];
             GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
              updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    });
    //comment
  }
  void updateAvailableDriversOnMap()
  {
    setState(() {
      markersSet.clear();
    });
    Set<Marker> tMakers= Set<Marker>();
    for (NearbyAvailableDrivers driver in GeoFireAssistant.nearbyAvailableDriversList)
      {
        LatLng driverAvailablePosition= LatLng(driver.latitude, driver.longitude);
        Marker marker = Marker(
            markerId: MarkerId('drivers${driver.key}'),
        position: driverAvailablePosition,
          icon: nearByIcon,
          rotation: AssistantMethods.createRandomNumber(360)
        );
             tMakers.add(marker);
      }
    setState(() {
      markersSet=tMakers;
    });
  }
  void createIconMarker()
  {
    if(nearByIcon == null)
      {
        ImageConfiguration imageConfiguration = createLocalImageConfiguration(context,size: Size(2, 2));
        BitmapDescriptor.fromAssetImage(imageConfiguration, 'images/car_ios.png').
    then((value) {
      nearByIcon=value;
        });
      }
  }
  void noDriverFounded()
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context)=> NoDriverAvailableDialog()
    );
  }
  void searchNearestDrivers()
  {
    if(availableDrivers.length == 0 )
      {
        cancelRideRequest();
        resetApp();
        noDriverFounded();
        return;
      }
    var driver = availableDrivers[0];
    notifyDriver(driver);
    availableDrivers.removeAt(0);
  }
  void notifyDriver(NearbyAvailableDrivers driver)
  {
    driverRef.child(driver.key).child('newRide').set(rideRequestRef.key);
    driverRef.child(driver.key).child('token').once().then((DataSnapshot snap){
      if(snap.value != null)
        {
          String token = snap.value.toString();
          AssistantMethods.sendNotificationToDriver(token, context, rideRequestRef.key);
        }
      else
        {
          return;
        }
      const oneSecondPassed = Duration(seconds: 1);
      var timer= Timer.periodic(oneSecondPassed, (timer) {
        if(state != 'requesting')
          {
            driverRef.child(driver.key).child('newRide').set('canceled');
            driverRef.child(driver.key).child('newRide').onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        driverRequestTimeOut = driverRequestTimeOut-1;

        driverRef.child(driver.key).child('newRide').onValue.listen((event) {
          if(event.snapshot.value.toString() == 'accepted')
            {
              driverRef.child(driver.key).child('newRide').onDisconnect();
              driverRequestTimeOut = 40;
              timer.cancel();
            }
        });


        if(driverRequestTimeOut == 0)
          {
            driverRef.child(driver.key).child('newRide').set('timeOut');
            driverRef.child(driver.key).child('newRide').onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
            searchNearestDrivers();
          }
      });
    } );
  }
}
