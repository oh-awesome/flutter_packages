// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enum_converters.dart';

// WARNING: Changes to `@JsonSerializable` classes need to be reflected in the
// below generated file. Run `flutter packages pub run build_runner watch` to
// rebuild and watch for further changes.
part 'ik_product_wrapper.g.dart';

/// Represents the response object returned by [IKRequestMaker.startProductRequest].
/// Contains information about a list of products and a list of invalid product identifiers.
@JsonSerializable()
@immutable
class IKProductResponseWrapper {
  /// Creates an [IKProductResponseWrapper] with the given product details.
  // TODO(stuartmorgan): Temporarily ignore const warning in other parts of the
  // federated package, and remove this.
  // ignore: prefer_const_constructors_in_immutables
  IKProductResponseWrapper(
      {required this.products, required this.invalidProductIdentifiers});

  /// Constructing an instance from a map from the Objective-C layer.
  ///
  /// This method should only be used with `map` values returned by [IKRequestMaker.startProductRequest].
  factory IKProductResponseWrapper.fromJson(Map<String, dynamic> map) {
    return _$SkProductResponseWrapperFromJson(map);
  }

  /// Stores all matching successfully found products.
  ///
  /// One product in this list matches one valid product identifier passed to the [IKRequestMaker.startProductRequest].
  /// Will be empty if the [IKRequestMaker.startProductRequest] method does not pass any correct product identifier.
  @JsonKey(defaultValue: <IKProductWrapper>[])
  final List<IKProductWrapper> products;

  /// Stores product identifiers in the `productIdentifiers` from [IKRequestMaker.startProductRequest] that are not recognized by the AppGallery.
  /// Will be empty if all the product identifiers are valid.
  @JsonKey(defaultValue: <String>[])
  final List<String> invalidProductIdentifiers;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IKProductResponseWrapper &&
        const DeepCollectionEquality().equals(other.products, products) &&
        const DeepCollectionEquality()
            .equals(other.invalidProductIdentifiers, invalidProductIdentifiers);
  }

  @override
  int get hashCode => Object.hash(products, invalidProductIdentifiers);
}

/// Used as a property in the [IKProductSubscriptionPeriodWrapper]. Minimum is a day and maximum is a year.
// The values of the enum options are matching the [IKProductPeriodUnit]'s values. Should there be an update or addition
// in the [IKProductPeriodUnit], this need to be updated to match.
enum IKSubscriptionPeriodUnit {
  /// An interval lasting one day.
  @JsonValue(0)
  day,

  /// An interval lasting one week.
  @JsonValue(1)
  week,

  /// An interval lasting one month.
  @JsonValue(2)
  month,

  /// An interval lasting one year.
  @JsonValue(3)
  year,
}

/// A period is defined by a [numberOfUnits] and a [unit], e.g for a 3 months period [numberOfUnits] is 3 and [unit] is a month.
/// It is used as a property in [IKProductDiscountWrapper] and [IKProductWrapper].
@JsonSerializable()
@immutable
class IKProductSubscriptionPeriodWrapper {
  /// Creates an [IKProductSubscriptionPeriodWrapper] for a `numberOfUnits`x`unit` period.
  // TODO(stuartmorgan): Temporarily ignore const warning in other parts of the
  // federated package, and remove this.
  // ignore: prefer_const_constructors_in_immutables
  IKProductSubscriptionPeriodWrapper(
      {required this.numberOfUnits, required this.unit});

  /// Constructing an instance from a map from the Objective-C layer.
  ///
  /// This method should only be used with `map` values returned by [IKProductDiscountWrapper.fromJson] or [IKProductWrapper.fromJson].
  factory IKProductSubscriptionPeriodWrapper.fromJson(
      Map<String, dynamic>? map) {
    if (map == null) {
      return IKProductSubscriptionPeriodWrapper(
          numberOfUnits: 0, unit: IKSubscriptionPeriodUnit.day);
    }
    return _$IKProductSubscriptionPeriodWrapperFromJson(map);
  }

  /// The number of [unit] units in this period.
  ///
  /// Must be greater than 0 if the object is valid.
  @JsonKey(defaultValue: 0)
  final int numberOfUnits;

  /// The time unit used to specify the length of this period.
  @IKSubscriptionPeriodUnitConverter()
  final IKSubscriptionPeriodUnit unit;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IKProductSubscriptionPeriodWrapper &&
        other.numberOfUnits == numberOfUnits &&
        other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(numberOfUnits, unit);
}

/// This is used as a property in the [IKProductDiscountWrapper].
// The values of the enum options are matching the [IKProductDiscountPaymentMode]'s values. Should there be an update or addition
// in the [IKProductDiscountPaymentMode], this need to be updated to match.
enum IKProductDiscountPaymentMode {
  /// Allows user to pay the discounted price at each payment period.
  @JsonValue(0)
  payAsYouGo,

  /// Allows user to pay the discounted price upfront and receive the product for the rest of time that was paid for.
  @JsonValue(1)
  payUpFront,

  /// User pays nothing during the discounted period.
  @JsonValue(2)
  freeTrail,

  /// Unspecified mode.
  @JsonValue(-1)
  unspecified,
}

/// This is used as a property in the [IKProductDiscountWrapper].
/// The values of the enum options are matching the [IKProductDiscountType]'s
/// values.
///
/// Values representing the types of discount offers an app can present.
enum IKProductDiscountType {
  /// A constant indicating the discount type is an introductory offer.
  @JsonValue(0)
  introductory,

  /// A constant indicating the discount type is a promotional offer.
  @JsonValue(1)
  subscription,
}

/// Dart wrapper around IAP Kit [Product](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/iap-iap-V5#section346874219313).
///
/// A list of [IKProductWrapper] is returned in the [IKRequestMaker.startProductRequest] method, and
/// should be stored for use when making a payment.
@JsonSerializable()
@immutable
class IKProductWrapper {
  /// Creates an [IKProductWrapper] with the given product details.
  // TODO(stuartmorgan): Temporarily ignore const warning in other parts of the
  // federated package, and remove this.
  // ignore: prefer_const_constructors_in_immutables
  IKProductWrapper({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.localPrice,
    required this.microPrice,
    required this.originalLocalPrice,
    required this.originalMicroPrice,
    required this.currency,
    this.status,
    // this.subscriptionInfo,
    // this.promotionalOffers,
    this.jsonRepresentation,
  });

  /// Constructing an instance from a map from the ets layer.
  ///
  /// This method should only be used with `map` values returned by [IKProductResponseWrapper.fromJson].
  factory IKProductWrapper.fromJson(Map<String, dynamic> map) {
    return _$IKProductWrapperFromJson(map);
  }

  /// The product ID.
  final String id;

  /// The product type.
  final ProductType type;

  /// The product name configured in AppGallery Connect, shown in the IAP
  /// checkout UI.
  final String name;

  /// The product description configured in AppGallery Connect.
  final String description;

  /// The displayed price, in the form "currency + price" (e.g. "EUR 0.15", or
  /// "￥0.15" in the Chinese mainland). Tax included.
  final String localPrice;

  /// The actual price in micro units, i.e. the actual price multiplied by
  /// 1,000,000 (e.g. $1.99 -> 1990000).
  final int microPrice;

  /// The original displayed price, in the same "currency + price" format as
  /// the current price. Tax included.
  final String originalLocalPrice;

  /// The original price in micro units, i.e. the original price multiplied by
  /// 1,000,000.
  final int originalMicroPrice;

  /// The ISO 4217 currency code used to pay for the product, e.g. USD, CNY,
  /// MYR.
  final String currency;

  /// The product status.
  final ProductStatus? status;

  /// Information about the auto-renewable subscription. Optional.
  // final SubscriptionInfo? subscriptionInfo;

  /// The list of promotional offers supported by the subscription product.
  // final PromotionalOffer[]? promotionalOffers;

  /// The raw JSON string of the product details.
  final String? jsonRepresentation;
}

/// The type of the product.
enum ProductType {
  /// Consumable product.
  @JsonValue(0)
  CONSUMABLE,

  /// Non-consumable product.
  @JsonValue(1)
  NONCONSUMABLE,

  /// Auto-renewable subscription product.
  @JsonValue(2)
  AUTORENEWABLE,

  /// Non-renewable subscription product.
  @JsonValue(3)
  NONRENEWABLE,
}

/// The status of the product.
enum ProductStatus {
  /// The product is valid.
  @JsonValue(0)
  VALID,

  /// The product has been canceled (deleted). It can no longer be subscribed
  /// or renewed.
  @JsonValue(1)
  CANCELED,

  /// The product is offline. New subscriptions are not allowed, but existing
  /// subscribers can still renew.
  @JsonValue(3)
  OFFLINE,
}
