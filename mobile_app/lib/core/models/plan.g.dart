// ??? ????????
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlanImpl _$$PlanImplFromJson(Map<String, dynamic> json) => _$PlanImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: _descriptionFromJson(json['description']),
  price: _priceFromJson(json['price']),
  duration: _durationFromJson(json['duration']),
  planType: json['plan_type'] as String,
  features: json['features'] == null
      ? const []
      : _featuresFromJson(json['features']),
  appleProductId: json['apple_product_id'] as String?,
);

Map<String, dynamic> _$$PlanImplToJson(_$PlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'duration': instance.duration,
      'plan_type': instance.planType,
      'features': instance.features,
      'apple_product_id': instance.appleProductId,
    };
