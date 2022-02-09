import 'dart:io';

import 'package:new_app/domain/model/buyer_id.dart';
import 'package:new_app/domain/model/navigator_location.dart';

class DeliveredOrderRequest {
  final String id;
  final NavigatorLocation location;
  final File signature;
  final String deliveryType;
  final String leftPackageMessage;
  final File leftPackageImage;
  final BuyerIdRequest buyerId;
  final DateTime deliveredAt;

  const DeliveredOrderRequest.withoutAlcoholInPerson(
    this.id,
    this.location,
    this.deliveryType,
    this.deliveredAt,
  )   : signature = null,
        leftPackageMessage = null,
        leftPackageImage = null,
        buyerId = null;

  const DeliveredOrderRequest.withoutAlcoholDropOff(
    this.id,
    this.location,
    this.deliveryType,
    this.leftPackageMessage,
    this.leftPackageImage,
    this.deliveredAt,
  )   : signature = null,
        buyerId = null;

  const DeliveredOrderRequest.withAlcohol(
    this.id,
    this.location,
    this.deliveryType,
    this.signature,
    this.buyerId,
    this.deliveredAt,
  )   : leftPackageMessage = null,
        leftPackageImage = null;
}

class BuyerIdRequest {
  final String type;
  final File image;
  final String imageUrl;
  final String name;
  final String number;
  final DateTime dateOfBirth;

  BuyerIdRequest(
    this.type,
    this.image,
    this.imageUrl,
    this.name,
    this.number,
    this.dateOfBirth,
  );

  BuyerIdRequest.fromBuyerId(BuyerId buyerId)
      : type = buyerId.type,
        imageUrl = buyerId.imageUrl,
        image = null,
        name = buyerId.name,
        number = buyerId.number,
        dateOfBirth = buyerId.dateOfBirth;
}
