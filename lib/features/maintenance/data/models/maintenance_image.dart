import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_image.freezed.dart';

@freezed
abstract class MaintenanceImage with _$MaintenanceImage {
  const factory MaintenanceImage({
    required String id,
    required String maintenanceRequestId,
    required String imageUrl,
  }) = _MaintenanceImage;

  factory MaintenanceImage.fromRow(Map<String, dynamic> row) => MaintenanceImage(
        id: row['id'] as String,
        maintenanceRequestId: row['maintenance_request_id'] as String,
        imageUrl: row['image_url'] as String,
      );
}
