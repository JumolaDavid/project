import 'package:new_app/domain/model/delivered_order_request.dart';
import 'package:new_app/domain/service/delivered_order.dart';
import 'package:new_app/infrastructure/location/service.dart';

class DeliveredOrderFacade {
  final DeliveredOrderService _deliveredOrderService;
  final LocationService _locationService;

  DeliveredOrderFacade(this._deliveredOrderService, this._locationService);

  Future<void> markOrderAsDelivered(DeliveredOrderRequest request) =>
      _deliveredOrderService.markOrderAsDelivered(request);

  Future<DeviceLocation> getCurrentLocation() =>
      _locationService.getCurrentLocation();
}
