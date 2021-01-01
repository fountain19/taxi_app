class Placepreditions
{
  String secondary_text;
  String main_text;
  String place_id;

  Placepreditions({this.main_text,this.secondary_text,this.place_id});
  Placepreditions.fromJson(Map<String,dynamic> json)
  {
    place_id=json['place_id'];
    main_text=json['structured_formatting']['main_text'];
    secondary_text=json['structured_formatting']['secondary_text'];
  }
}