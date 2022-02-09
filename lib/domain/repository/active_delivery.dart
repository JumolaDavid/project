import 'package:new_app/backbone/exception.dart';
import 'package:new_app/domain/model/active_delivery.dart';

abstract class ActiveDeliveryRepository {
  Future<ActiveDelivery> fetch(String deliveryId);
}

class ActiveDeliveryException extends DocumentedException {
  ActiveDeliveryException({String message, Object cause})
      : super(message: message, cause: cause);
}
