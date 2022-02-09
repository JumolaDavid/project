import 'package:new_app/backbone/meta/ioc/di/container.dart';
import 'package:new_app/bloc/order_delivered/bloc.dart';
import 'package:new_app/bloc/order_delivered/facade.dart';
import 'package:new_app/domain/model/delivered_order_request.dart';
import 'package:new_app/infrastructure/location/service.dart';
import 'package:new_app/network/http/client.dart';
import 'package:new_app/network/http/service/domain/active_delivery_actions.dart';
import 'package:new_app/presentation/model/delivered_order_request.dart';

/// This factory serves to create and configure [DeliveredOrderBlocFactory]

class DeliveredOrderBlocFactory {
  final DeliveredOrderRequestPM request;

  DeliveredOrderBlocFactory.withoutAlcohol(String id)
      : request = DeliveredOrderRequestPM(id);

  DeliveredOrderBlocFactory.withAlcohol(String id, BuyerIdRequest buyerId)
      : request = DeliveredOrderRequestPM.buyerId(id, buyerId);

  DeliveredOrderBloc create(DIContainer container) {
    return DeliveredOrderBloc(
      DeliveredOrderFacade(
        HttpActiveDeliveryActionsService(
          container.get<HttpClient>(),
          PersistentActiveDeliveriesMetadata(
            container.get<KeyValueStorage>(),
          ),
        ),
        new_appLocationService(),
      ),
      request,
    );
  }
}
