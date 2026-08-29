import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

enum AppRole { admin, technician, customer }

AppRole appRoleFromString(String value) => AppRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => AppRole.customer,
    );

/// Mirrors public.users — the profile row every authenticated person has.
/// This is what the router uses to decide which app shell to show.
///
/// Hand-written row mapper (not json_serializable) because of the enum
/// mapping to/from the Postgres `user_role` type — trivial enough not to
/// need codegen here. Named `fromRow` rather than `fromJson` on purpose:
/// freezed special-cases a factory literally named `fromJson` and expects
/// json_serializable's generated `_$AppUserFromJson`, which we don't want.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required AppRole role,
    required String fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    required bool isActive,
  }) = _AppUser;

  factory AppUser.fromRow(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: appRoleFromString(json['role'] as String),
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}
