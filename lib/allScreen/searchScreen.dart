
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/allWidgets/divider.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/assistants/requestAssintants.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/dataHandler/appData.dart';
import 'package:taxi_app/models/address.dart';
import 'package:taxi_app/models/placePredictions.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickUpTextEditingController=TextEditingController();
  TextEditingController dropOffTextEditingController=TextEditingController();
   List<Placepreditions> placePredictionList= [];
  @override
  Widget build(BuildContext context) {
    String placeAddress= Provider.of<AppData>(context).pickUpLocation.placeName??'';
    pickUpTextEditingController.text=placeAddress;
    return Scaffold(
      body:ListView(
        children: [
          Column(
            children: [
              Container(
                height: 215.0,
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7,0.7)
                      )
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 25.0,right: 25.0,top: 25.0,bottom: 20.0),
                  child: Column(
                    children: [
                      SizedBox(height: 5.0,),
                      Stack(
                        children: [
                          GestureDetector
                            (child: Icon(Icons.arrow_back),
                            onTap: ()=> Navigator.pop(context),
                          ),
                          Center(child: Text('Set drop off',style: TextStyle(
                              fontSize: 18.0,fontFamily: 'bolt-semibold'
                          ),),),
                        ],
                      ),
                      SizedBox(height: 16.0,),
                      Row(
                        children: [
                          Image.asset('images/pickicon.png',height: 16.0,width: 16.0,),
                          SizedBox(width: 18.0,),
                          Expanded(child: Container(
                            decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5.0)
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: TextField(
                                controller: pickUpTextEditingController,
                                decoration: InputDecoration(
                                    hintText: 'Pick up Location',
                                    fillColor: Colors.grey[400],
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11,top: 8.0,bottom: 8.0)
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                      SizedBox(height: 10.0,),
                      Row(
                        children: [
                          Image.asset('images/desticon.png',height: 16.0,width: 16.0,),
                          SizedBox(width: 18.0,),
                          Expanded(child: Container(
                            decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5.0)
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: TextField(
                                onChanged: (val)
                                {
                                  findPlace(val);
                                },
                                controller: dropOffTextEditingController,
                                decoration: InputDecoration(
                                    hintText: 'Where to ?',
                                    fillColor: Colors.grey[400],
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11,top: 8.0,bottom: 8.0)
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // tile for predictions
              SizedBox(height: 10.0,),
              (placePredictionList.length>1)?
              Padding(padding: EdgeInsets.symmetric(vertical:8,horizontal: 16),
                child: ListView.separated(
                  padding: EdgeInsets.all(0.0),
                  itemBuilder: (context,index)
                  {
                    return PredictionTile(placepreditions: placePredictionList[index],);
                  },
                  separatorBuilder:(BuildContext context, int index)=> DividerWidget(),
                  itemCount: placePredictionList.length,
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                ),
              )
                  :Container()
            ],
          ),
        ],
      )
    );
  }
  void findPlace(String placeName)async
  {
    if(placeName.length>1)
      {
        // we are adding to this url  in the end '&components=country:sy' to search about name of city in our country
        String autoCompleteUrl= 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:tr';
        var res =await RequestAssistant.getRequest(autoCompleteUrl);
        if(res == 'failed')
          {
            return;
          }
       if(res['status']=='OK')
         {
           var preditions= res['predictions'];
           var placeList = (preditions as List).map((e) => Placepreditions.fromJson(e)).toList();
              setState(() {
                placePredictionList = placeList;
              });
         }
      }
  }
}

class PredictionTile extends StatelessWidget {

  final Placepreditions placepreditions;
  PredictionTile({Key key,this.placepreditions }):super (key: key);
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: (){
           getPlaceAddress(placepreditions.place_id, context);
      },
      child: Container(
         child:Column(
           children: [
             SizedBox(width: 10.0,),
             Row(
               children: [
                 Icon(Icons.add_location),
                 SizedBox(width: 14.0,),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       SizedBox(height: 8.0,),
                       Text(placepreditions.main_text,overflow: TextOverflow.ellipsis,style: TextStyle(fontSize: 16.0),),
                       SizedBox(height: 2.0,),
                       Text(placepreditions.secondary_text,overflow: TextOverflow.ellipsis,style: TextStyle(fontSize: 12.0,color: Colors.grey),),
                       SizedBox(height: 8.0,),
                     ],
                   ),
                 )
               ],
             ),
             SizedBox(width: 10.0,),
           ],
         )
      ),
    );
  }
  void getPlaceAddress(String placeId,context) async
  {

    showDialog(
      context: context,
      builder: (BuildContext context )=>ProgressDialog(message: 'Setting dropOff,please wait...',)
    );
    String placeDetailsUrl='https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey';
    var res = await RequestAssistant.getRequest(placeDetailsUrl);
    Navigator.pop(context);

    if(res == 'failed')
      {return;}
    if(res['status']=='OK')
      {
        Address address = Address();
        address.placeName=res['result']['name'];
        address.placeId=placeId;
        address.longitude=res['result']['geometry']['location']['lng'];
        address.latitude=res['result']['geometry']['location']['lat'];
         Provider.of<AppData>(context,listen: false).updateDropOffLocationAddress(address);
         print('this is drop off locaTION :::::');
        print(address.placeName);
        Navigator.pop(context,'obtain direction');
      }
  }
}
