import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/location_models.dart';
import '../../providers/locations_providers.dart';

/// Admin → مناطق الخدمة: cities, each switched on/off, each opening its
/// service areas. Coverage changes take effect on customers' saved addresses
/// immediately (re-resolved server-side, 0032).
class AdminCitiesScreen extends ConsumerWidget {
  const AdminCitiesScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, City city) async {
    final turningOff = city.isActive;
    if (turningOff) {
      final ok = await showConfirmDialog(
        context,
        title: 'إيقاف ${city.nameAr}',
        message:
            'كل عناوين العملاء في ${city.nameAr} ستصبح غير مغطاة فورًا، '
            'ولن تظهر المدينة لعملاء جدد.',
        confirmLabel: 'إيقاف',
        isDangerous: true,
      );
      if (!ok || !context.mounted) return;
    }
    try {
      await ref
          .read(locationsRepositoryProvider)
          .setCityActive(city.id, !city.isActive);
      ref.invalidate(citiesProvider(activeOnly: false));
      ref.invalidate(citiesProvider());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider(activeOnly: false));

    return Scaffold(
      appBar: AppBar(title: const Text('مناطق الخدمة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminCityNew),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('إضافة مدينة'),
      ),
      body: citiesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل المدن',
          onRetry: () => ref.invalidate(citiesProvider(activeOnly: false)),
        ),
        data: (cities) {
          if (cities.isEmpty) {
            return const EmptyView(
              message: 'لا توجد مدن بعد',
              icon: Icons.location_city_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: cities.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final city = cities[i];
              return ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: Text(city.nameAr),
                subtitle: Text(
                  city.isActive ? 'مفعّلة' : 'متوقفة — لا تظهر للعملاء',
                ),
                onTap: () => context.push(Routes.adminCityAreas(city.id)),
                trailing: Switch(
                  value: city.isActive,
                  onChanged: (_) => _toggle(context, ref, city),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
