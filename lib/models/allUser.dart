import 'package:firebase_database/firebase_database.dart';

class Users
{
  String id,email,name,phone;
  Users({this.phone,this.id,this.email,this.name});
  Users.fromSnapshot(DataSnapshot dataSnapshot)
  {
    id=dataSnapshot.key;
    name=dataSnapshot.value['name'];
    email=dataSnapshot.value['email'];
    phone=dataSnapshot.value['phone'];
  }
}