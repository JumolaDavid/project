import 'package:new_app/backbone/exception.dart';
import 'package:new_app/domain/model/navigator_location.dart';

abstract class ActiveDeliveryProcessService {
  Future<void> cancelPikUp(String deliveryId);

  Future<void> markPikedUp(
    String deliveryId,
    NavigatorLocation navigatorLocation,
  );

  Future<void> returnOrder(String deliveryId, String reason, String message);
}

class ActiveDeliveryActionsException extends DocumentedException {
  ActiveDeliveryActionsException({String message, Object cause})
      : super(message: message, cause: cause);
}
