import 'package:taxi_app/models/nearbyAvaibelDrivers.dart';

class GeoFireAssistant{
  static List<NearbyAvailableDrivers> nearbyAvailableDriversList =[];

  static void removeDriverFromList(String key)
  {
    int index=nearbyAvailableDriversList.indexWhere((element) => element.key== key);
    nearbyAvailableDriversList.removeAt(index);
  }
  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver)
  {
    int index=nearbyAvailableDriversList.indexWhere((element) => element.key== driver.key);
    nearbyAvailableDriversList[index].longitude=driver.longitude;
    nearbyAvailableDriversList[index].latitude=driver.latitude;
  }
}