import 'dart:io';

import 'package:new_app/domain/model/navigator_location.dart';
import 'package:new_app/domain/model/delivered_order_request.dart';
import 'package:new_app/domain/repository/active_delivery.dart';
import 'package:new_app/domain/service/active_delivery_process.dart';
import 'package:new_app/domain/service/delivered_order.dart';
import 'package:new_app/network/http/client.dart';

class HttpActiveDeliveryActionsService
    implements ActiveDeliveryProcessService, DeliveredOrderService {
  static const String _path = "deliveries";
  static const String _pathCancelPikUp = "cancel-pickup";
  static const String _pathPikedUp = "picked-up";
  static const String _pathReturn = "return";
  static const String _pathDelivered = "delivered";

  final HttpClient _client;
  final ActiveDeliveriesMetadata _metadata;

  HttpActiveDeliveryActionsService(this._client, this._metadata);

  @override
  Future<void> cancelPikUp(String deliveryId) async {
    try {
      await _client.post("$_path/$deliveryId/$_pathCancelPikUp");
      _metadata.removeActiveDelivery(deliveryId);
      _metadata.removeCancelledDeliveries(deliveryId);
    } on SocketException {
      _metadata.setCancelledDeliveries(deliveryId);
    } on Object catch (e) {
      throw ActiveDeliveryException(cause: e);
    }
  }

  @override
  Future<void> markPikedUp(
    String deliveryId,
    NavigatorLocation location,
  ) async {
    try {
      await _client
          .post("$_path/$deliveryId/$_pathPikedUp", data: <String, dynamic>{
        _keyId: deliveryId,
        _keyLat: location.latitude,
        _keyLng: location.longitude,
        _keyPickedUpAt: location.dateTime.toIso8601String(),
      });
      _metadata.setPickedUpDeliveries(
        deliveryId,
        location.latitude,
        location.longitude,
        location.dateTime.toIso8601String(),
      );
    } on Object catch (e) {
      throw ActiveDeliveryException(cause: e);
    }
  }

  @override
  Future<void> returnOrder(
    String deliveryId,
    String reason,
    String message,
  ) async {
    try {
      await _client
          .post("$_path/$deliveryId/$_pathReturn", data: <String, dynamic>{
        _keyId: deliveryId,
        _keyReason: reason,
        _keyMessage: message,
      });
    } on Object catch (e) {
      throw ActiveDeliveryException(cause: e);
    }
  }

  @override
  Future<void> markOrderAsDelivered(DeliveredOrderRequest request) async {
    try {
      await _client.post("$_path/${request.id}/$_pathDelivered",
          data: DeliveredOrderRequestDto(request).getRequestBody());
    } on Object catch (e) {
      throw DeliveredOrderException(cause: e);
    }
  }
}

const String _keyId = "id";
const String _keyLat = "lat";
const String _keyLng = "lng";
const String _keyPickedUpAt = "picked_up_at";
const String _keyReason = "reason";
const String _keyMessage = "message";
