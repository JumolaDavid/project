import 'package:new_app/bloc/location_tracking/facade.dart';
import 'package:new_app/infrastructure/location_tracking/decorator.dart';
import 'package:new_app/network/http/client.dart';
import 'package:new_app/network/http/dto/active_delivery/parsing_factory.dart';
import 'package:new_app/network/http/repository/active_deliveries.dart';
import 'package:new_app/network/http/service/domain/location_tracking.dart';
import 'package:new_app/persistence/active_deliveries/metadata.dart';
import 'package:new_app/persistence/storage.dart';

/// This factory serves to create and configure [LocationTrackingFacade]

class LocationTrackingFacadeFactory {
  const LocationTrackingFacadeFactory();

  LocationTrackingFacade create(HttpClient client, KeyValueStorage storage) {
    return LocationTrackingFacade(
      IntervalLocationTrackingServiceDecorator(
        HttpLocationTrackingService(client),
        storage,
      ),
      HttpActiveDeliveriesRepository(
        client,
        ActiveDeliveryParsingFactory.def(),
        PersistentActiveDeliveriesMetadata(storage),
      ),
    );
  }
}
