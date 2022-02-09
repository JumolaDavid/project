import 'dart:io';

import 'package:new_app/assembly/bloc/location_tracking/facade.dart';
import 'package:new_app/bloc/authenticate/bloc.dart';
import 'package:new_app/bloc/location_tracking/bloc.dart';
import 'package:new_app/bloc/location_tracking/facade.dart';
import 'package:new_app/infrastructure/location/service.dart';
import 'package:new_app/network/http/client.dart' as new_app;
import 'package:new_app/persistence/storage.dart';

/// This factory serves to create and configure [LocationTrackingBloc]

class LocationTrackingBlocFactory {
  const LocationTrackingBlocFactory();

  LocationTrackingBloc create(
    new_app.HttpClient client,
    AuthBloc authBloc,
    KeyValueStorage storage,
  ) {
    final LocationService locationService = new_appLocationService();
    final LocationTrackingFacade facade =
        LocationTrackingFacadeFactory().create(client, storage);
    if (Platform.isIOS) {
      return IOSLocationTrackingBloc(locationService, facade, authBloc);
    } else {
      return AndroidLocationTrackingBloc(locationService, facade, authBloc);
    }
  }
}
