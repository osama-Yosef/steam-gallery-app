import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cart/data/models/cart.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../../locations/data/models/location_models.dart';
import '../../../../locations/presentation/providers/locations_providers.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/checkout_address_picker.dart';

/// Order summary, delivery address (a saved, service-checked address —
/// 0036) and notes. Lines and their prices come from the server cart
/// (0035); this screen never computes or sends money itself. Payment method
/// selection (gateway / InstaPay / wallet) arrives with Phases 10–14 — for
/// now every order is cash on delivery, same as the existing ERP flow.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _notesCtrl = TextEditingController();
  // Generated once and reused across retries of the SAME checkout attempt
  // so a flaky connection can't create duplicate orders (NFR-11).
  final String _clientRequestId = const Uuid().v4();
  bool _submitting = false;
  String? _selectedAddressId;
  bool _autoSelected = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Runs once the addresses first load: prefers the default address if
  /// it's covered, otherwise the first covered one, otherwise nothing (the
  /// customer must pick — every option might be outside coverage).
  void _autoSelectAddress(List<CustomerAddress> addresses) {
    if (_autoSelected || addresses.isEmpty) return;
    _autoSelected = true;
    if (addresses.any((a) => a.id == _selectedAddressId)) return;
    CustomerAddress? pick;
    for (final a in addresses) {
      if (a.isDefault && a.isServiceable) {
        pick = a;
        break;
      }
    }
    if (pick == null) {
      for (final a in addresses) {
        if (a.isServiceable) {
          pick = a;
          break;
        }
      }
    }
    _selectedAddressId = pick?.id;
  }

  Future<void> _pickAddress(List<CustomerAddress> addresses) async {
    final result = await showAddressPickerSheet(
      context,
      addresses: addresses,
      selectedId: _selectedAddressId,
    );
    if (result == addAddressSentinel) {
      if (mounted) await context.push(Routes.customerAddressNew);
      ref.invalidate(myAddressesProvider);
    } else if (result != null && mounted) {
      setState(() => _selectedAddressId = result);
    }
  }

  Future<void> _placeOrder(CartSummary cart) async {
    final profile = ref.read(currentUserProfileProvider).value;
    final addressId = _selectedAddressId;
    if (profile == null || !cart.canCheckout || addressId == null) return;

    setState(() => _submitting = true);
    try {
      final orderId = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerId: profile.id,
            items: [
              for (final line in cart.items)
                (productId: line.productId, quantity: line.quantity),
            ],
            addressId: addressId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            clientRequestId: _clientRequestId,
          );
      // The order snapshotted its own prices and address server-side; the
      // cart's job is done, so empty it (best-effort — a failure here
      // shouldn't block navigating to the order that was already created).
      unawaited(ref.read(cartProvider.notifier).clear());
      if (mounted) {
        context.pushReplacement(Routes.customerOrderDetail(orderId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(myAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: cartAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل السلة',
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return const EmptyView(
              message: 'السلة فارغة',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return addressesAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: 'تعذَّر تحميل العناوين',
              onRetry: () => ref.invalidate(myAddressesProvider),
            ),
            data: (addresses) {
              _autoSelectAddress(addresses);
              CustomerAddress? selected;
              for (final a in addresses) {
                if (a.id == _selectedAddressId) {
                  selected = a;
                  break;
                }
              }
              final canSubmit =
                  cart.canCheckout &&
                  selected != null &&
                  selected.isServiceable;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'عنوان التوصيل',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (addresses.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: const Text('أضف عنوان توصيل أولًا'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () async {
                          await context.push(Routes.customerAddressNew);
                          ref.invalidate(myAddressesProvider);
                        },
                      ),
                    )
                  else
                    CheckoutAddressCard(
                      selected: selected,
                      onTap: () => _pickAddress(addresses),
                    ),
                  if (selected != null && !selected.isServiceable) ...[
                    const SizedBox(height: 8),
                    Text(
                      'العنوان ده خارج نطاق التغطية دلوقتي — اختر عنوانًا تانيًا.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملخص الطلب',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(),
                          for (final item in cart.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} × ${item.quantity}',
                                    ),
                                  ),
                                  Text(Formatters.currency(item.lineTotal)),
                                ],
                              ),
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'الإجمالي',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                Formatters.currency(cart.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                    maxLines: 2,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 4),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.payments_outlined),
                    title: Text('طريقة الدفع'),
                    subtitle: Text('الدفع عند الاستلام'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _submitting || !canSubmit
                        ? null
                        : () => _placeOrder(cart),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('إرسال الطلب'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
