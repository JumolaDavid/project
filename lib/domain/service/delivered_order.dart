import 'package:new_app/backbone/exception.dart';
import 'package:new_app/domain/model/delivered_order_request.dart';

abstract class DeliveredOrderService {
  Future<void> markOrderAsDelivered(DeliveredOrderRequest request);
}

class DeliveredOrderException extends DocumentedException {
  DeliveredOrderException({String message, Object cause})
      : super(message: message, cause: cause);
}
