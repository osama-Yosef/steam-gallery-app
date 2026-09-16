import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/maps/map_widget_factory.dart';
import '../../../../../core/maps/maps_providers.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/locations_providers.dart';

/// One city's coverage: every area on a map (active highlighted, inactive
/// grey) and as a list to open for editing.
class AdminCityAreasScreen extends ConsumerWidget {
  final String cityId;
  const AdminCityAreasScreen({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref
        .watch(citiesProvider(activeOnly: false))
        .value
        ?.where((c) => c.id == cityId)
        .firstOrNull;
    final areasAsync = ref.watch(
      serviceAreasProvider(cityId, activeOnly: false),
    );
    final mapFactory = ref.watch(mapWidgetFactoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(city?.nameAr ?? 'المناطق')),
      floatingActionButton: city == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.adminServiceAreaNew(cityId)),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة منطقة'),
            ),
      body: city == null
          ? const LoadingView()
          : areasAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المناطق',
                onRetry: () => ref.invalidate(
                  serviceAreasProvider(cityId, activeOnly: false),
                ),
              ),
              data: (areas) => ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  SizedBox(
                    height: 260,
                    child: mapFactory.preview(
                      center: city.center,
                      zoom: MapZoom.city,
                      circles: [for (final a in areas) a.toCircle()],
                    ),
                  ),
                  if (!city.isActive)
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text(
                        'المدينة متوقفة: لا منطقة فيها مغطاة حتى تفعيلها.',
                      ),
                    ),
                  if (areas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'لا توجد مناطق بعد. أي عنوان في هذه المدينة غير مغطى.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final a in areas)
                    ListTile(
                      leading: Icon(
                        Icons.radio_button_checked,
                        color: a.isActive ? null : Colors.grey,
                      ),
                      title: Text(a.nameAr),
                      subtitle: Text(
                        '${a.isActive ? 'مفعّلة' : 'متوقفة'} · نصف قطر ${a.radiusKm.toStringAsFixed(1)} كم',
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.push(
                        Routes.adminServiceAreaEdit(cityId, a.id),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
