import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_app/bloc/order_delivered/facade.dart';
import 'package:new_app/domain/model/delivered_order_request.dart';
import 'package:new_app/presentation/model/delivered_order_request.dart';


class DeliveredOrderBloc with BehaviorSubjectBloc<DeliveredOrderState> {
  final DeliveredOrderFacade _facade;
  final picker = ImagePicker();

  DeliveredOrderBloc(this._facade, DeliveredOrderRequestPM request) {
    currentState = DeliveredOrderState.idle(request);
  }

  Future<void> deliverInPersonWithoutAlcohol() async {
    currentState = DeliveredOrderState.processing(currentState.request);
    try {
      final DeviceLocation currentLocation = await _facade.getCurrentLocation();
      final DeliveredOrderRequestPM request = currentState.request.copyWith(
        deliveryType: _deliveryTypes[0],
        location: NavigatorLocation(
          currentLocation.latitude,
          currentLocation.longitude,
          currentLocation.dateTime,
        ),
        deliveredAt: DateTime.now(),
      );
      await _facade
          .markOrderAsDelivered(request.toDomainInPersonWithoutAlcohol());
      currentState = DeliveredOrderState.success(request);
    } on Object catch (e) {
      _detectExceptionAndUpdateState(e);
    }
  }

  Future<void> dropOff(String leftPackageMessage) async {
    if (leftPackageMessage.isEmpty) {
      currentState = DeliveredOrderState.exception(
          currentState.request,
          ErrorPM.presentation(
              "drop_off_fields_error", new_appStrings.dropOffFieldsError));
      return;
    }
    currentState = DeliveredOrderState.processing(currentState.request);
    try {
      final DeviceLocation currentLocation = await _facade.getCurrentLocation();
      final DeliveredOrderRequestPM request = currentState.request.copyWith(
        deliveryType: _deliveryTypes[1],
        leftPackageMessage: leftPackageMessage,
        location: NavigatorLocation(
          currentLocation.latitude,
          currentLocation.longitude,
          currentLocation.dateTime,
        ),
        deliveredAt: DateTime.now(),
      );
      await _facade.markOrderAsDelivered(request.toDomainDropOff());
      currentState = DeliveredOrderState.success(request);
    } on Object catch (e) {
      _detectExceptionAndUpdateState(e);
    }
  }

  Future<void> deliverInPersonWithAlcohol(
    BuyerIdRequest buyerId,
    File signature,
  ) async {
    if (buyerId == null) {
      currentState = DeliveredOrderState.exception(currentState.request,
          ErrorPM.presentation("need_buyer_id", new_appStrings.needBuyerId));
      return;
    }
    currentState = DeliveredOrderState.processing(currentState.request);
    try {
      final DeviceLocation currentLocation = await _facade.getCurrentLocation();
      final DeliveredOrderRequestPM request = currentState.request.copyWith(
        deliveryType: _deliveryTypes[0],
        location: NavigatorLocation(
          currentLocation.latitude,
          currentLocation.longitude,
          currentLocation.dateTime,
        ),
        idType: buyerId.type,
        idNumber: buyerId.number,
        idName: buyerId.name,
        idImage: buyerId.image,
        idDateOfBirth: buyerId.dateOfBirth,
        signature: signature,
        deliveredAt: DateTime.now(),
      );
      await _facade.markOrderAsDelivered(request.toDomainWithAlcohol());
      currentState = DeliveredOrderState.success(request);
    } on Object catch (e) {
      _detectExceptionAndUpdateState(e);
    }
  }

  void _detectExceptionAndUpdateState(Object e) {
    if (e.toString().contains("navigator_not_assigned")) {
      currentState = DeliveredOrderState.exception(currentState.request,
          ErrorPM.presentation(e.toString(), new_appStrings.notAssignedError));
    } else if (e.toString().contains("already_delivered")) {
      currentState = DeliveredOrderState.exception(
          currentState.request,
          ErrorPM.presentation(
              e.toString(), new_appStrings.alreadyDeliveredError));
    } else {
      currentState = DeliveredOrderState.exception(
          currentState.request,
          ErrorPM.presentation(
              e.toString(), new_appStrings.somethingWrongTryLater));
    }
  }

  Future<void> addDropOffImage() async {
    try {
      final PickedFile file = await picker.getImage(source: ImageSource.camera);
      final File pickedFile = File(file.path);
      // final File pickedFile =
          // await ImagePicker.pickImage(source: ImageSource.camera);
         
      final DeliveredOrderRequestPM request =
          currentState.request.copyWith(leftPackageImage: pickedFile);
      currentState = DeliveredOrderState.idle(request);
    } catch (_) {
      currentState = DeliveredOrderState.exception(
          currentState.request,
          ErrorPM.presentation(
              "failed_to_add_photo", new_appStrings.failedToAddPhoto));
    }
  }

  Future<void> addBuyerIdImage() async {
    try {
      final PickedFile file = await picker.getImage(source: ImageSource.camera);
      final File pickedFile = File(file.path);
      // final File pickedFile =
          // await ImagePicker.pickImage(source: ImageSource.camera);
      final DeliveredOrderRequestPM request =
          currentState.request.copyWith(idImage: pickedFile);
      currentState = DeliveredOrderState.idle(request);
    } catch (_) {
      currentState = DeliveredOrderState.exception(
          currentState.request,
          ErrorPM.presentation(
              "failed_to_add_photo", new_appStrings.failedToAddPhoto));
    }
  }

  Future<void> addBuyerIdDateOfBirth(DateTime date) async {
    try {
      final DeliveredOrderRequestPM request =
          currentState.request.copyWith(idDateOfBirth: date);
      currentState = DeliveredOrderState.idle(request);
    } catch (_) {
      currentState = DeliveredOrderState.exception(
          currentState.request,
          ErrorPM.presentation("failed_to_add_date_of_birth",
              new_appStrings.failedToAddDateOfBirth));
    }
  }

  void dispose() {
    disposeSubjectBloc();
  }
}

class DeliveredOrderState with ErrorProneState {
  final DeliveredOrderRequestPM request;
  @override
  final ErrorPM error;
  final bool _isProcessing;
  final bool _isSuccess;

  DeliveredOrderState(
      this.request, this.error, this._isProcessing, this._isSuccess);

  DeliveredOrderState.idle(this.request)
      : error = null,
        _isProcessing = false,
        _isSuccess = false;

  DeliveredOrderState.exception(this.request, this.error)
      : _isProcessing = false,
        _isSuccess = false;

  DeliveredOrderState.processing(this.request)
      : error = null,
        _isProcessing = true,
        _isSuccess = false;

  DeliveredOrderState.success(this.request)
      : error = null,
        _isProcessing = false,
        _isSuccess = true;

  bool get isIdle => !hasError && !_isProcessing && !_isSuccess;

  bool get isException => hasError && !_isProcessing && !_isSuccess;

  bool get isProcessing => !hasError && _isProcessing && !_isSuccess;

  bool get isSuccess => !hasError && !_isProcessing && _isSuccess;
}

final BuiltList<String> _deliveryTypes =
    <String>["InPerson", "LeftPackage"].toBuiltList();
