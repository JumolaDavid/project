import 'dart:io';

import 'package:new_app/domain/model/delivered_order_request.dart';
import 'package:new_app/domain/model/navigator_location.dart';

class DeliveredOrderRequestPM {
  final String id;
  final NavigatorLocation location;
  final File signature;
  final String deliveryType;
  final String leftPackageMessage;
  final File leftPackageImage;
  final BuyerIdRequest buyerId;
  final DateTime deliveredAt;

  DeliveredOrderRequestPM(this.id)
      : location = null,
        signature = null,
        deliveryType = null,
        leftPackageMessage = null,
        leftPackageImage = null,
        buyerId = null,
        deliveredAt = null;

  DeliveredOrderRequestPM.buyerId(this.id, this.buyerId)
      : location = null,
        signature = null,
        deliveryType = null,
        leftPackageMessage = null,
        leftPackageImage = null,
        deliveredAt = null;

  DeliveredOrderRequestPM.full(
    this.id,
    this.location,
    this.signature,
    this.deliveryType,
    this.leftPackageMessage,
    this.leftPackageImage,
    this.buyerId,
    this.deliveredAt,
  );

  DeliveredOrderRequestPM copyWith({
    NavigatorLocation location,
    File signature,
    String deliveryType,
    String leftPackageMessage,
    File leftPackageImage,
    String idType,
    File idImage,
    String idName,
    String idNumber,
    DateTime idDateOfBirth,
    DateTime deliveredAt,
  }) {
    BuyerIdRequest buyerId;
    if (idType != null ||
        idImage != null ||
        idName != null ||
        idNumber != null ||
        idDateOfBirth != null) {
      if (this.buyerId == null) {
        buyerId = BuyerIdRequest(
          idType,
          idImage,
          this.buyerId?.imageUrl,
          idName,
          idNumber,
          idDateOfBirth,
        );
      } else {
        buyerId = BuyerIdRequest(
          idType ?? this.buyerId?.type,
          idImage ?? this.buyerId?.image,
          this.buyerId?.imageUrl,
          idName ?? this.buyerId?.name,
          idNumber ?? this.buyerId?.number,
          idDateOfBirth ?? this.buyerId?.dateOfBirth,
        );
      }
    }
    return DeliveredOrderRequestPM.full(
      this.id,
      location ?? this.location,
      signature ?? this.signature,
      deliveryType ?? this.deliveryType,
      leftPackageMessage ?? this.leftPackageMessage,
      leftPackageImage ?? this.leftPackageImage,
      buyerId ?? this.buyerId,
      deliveredAt ?? this.deliveredAt,
    );
  }

  DeliveredOrderRequest toDomainDropOff() {
    if (id == null ||
        location?.latitude == null ||
        location?.longitude == null ||
        deliveryType == null ||
        leftPackageMessage == null ||
        leftPackageImage == null ||
        deliveredAt == null) {
      throw ArgumentError.notNull(
          "id, location, deliveryType, leftPackageMessage, "
          "leftPackageImage, deliveredAt");
    }
    return DeliveredOrderRequest.withoutAlcoholDropOff(id, location,
        deliveryType, leftPackageMessage, leftPackageImage, deliveredAt);
  }

  DeliveredOrderRequest toDomainInPersonWithoutAlcohol() {
    if (id == null ||
        location?.latitude == null ||
        location?.longitude == null ||
        deliveryType == null ||
        deliveredAt == null) {
      throw ArgumentError.notNull("id, location, deliveryType, deliveredAt");
    }
    return DeliveredOrderRequest.withoutAlcoholInPerson(
        id, location, deliveryType, deliveredAt);
  }

  DeliveredOrderRequest toDomainWithAlcohol() {
    if (id == null ||
        location?.latitude == null ||
        location?.longitude == null ||
        deliveryType == null ||
        signature == null ||
        buyerId?.type == null ||
        (buyerId?.image == null && buyerId?.imageUrl == null) ||
        buyerId?.name == null ||
        buyerId?.number == null ||
        buyerId?.dateOfBirth == null ||
        deliveredAt == null) {
      throw ArgumentError.notNull("id, location, deliveryType, signature, "
          "buyerId.type, buyerId.image, buyerId.name, "
          "buyerId.number, buyerId.dob, deliveredAt");
    }
    return DeliveredOrderRequest.withAlcohol(
      id,
      location,
      deliveryType,
      signature,
      buyerId,
      deliveredAt,
    );
  }
}
