# المرحلة 5 — Flutter Architecture

## 1. اختيار State Management: **Riverpod** (مع `riverpod_generator`)

### لماذا Riverpod وليس Bloc

| المعيار | Riverpod | Bloc/Cubit |
|---|---|---|
| دمج Streams (Supabase Realtime) | `StreamProvider` مباشر وبسيط | يحتاج تحويل يدوي لـ Stream → Events → State |
| اعتماديات متعددة/مركّبة (Dashboard يعتمد على 5 مصادر) | `ref.watch` تركيبي طبيعي بدون Boilerplate | يحتاج BlocListener/MultiBlocProvider متداخل |
| Compile-time safety + Testability | Providers مستقلة عن `BuildContext`، سهلة الاختبار بمعزل | جيد أيضًا لكن يحتاج Context أحيانًا لـ Provider الشجرة |
| حجم الفريق/المشروع | مناسب لمشروع متوسط بفرق صغير — Boilerplate أقل | يفضَّل لفرق كبيرة تحتاج انضباط صارم في الحالات |
| Async مع Cache + Auto-dispose | مدمج (`autoDispose`, `family`) | يحتاج تصميم يدوي |

**القرار: Riverpod v2 مع Code Generation (`@riverpod`)**. هذا المشروع مليء بشاشات تعتمد Realtime (الصيانة، الإشعارات، Dashboard) وبيانات مركّبة من أكثر من مصدر (حساب صنايعي = بضاعة + مبيعات + تحصيل) — نمط `ref.watch` التركيبي في Riverpod أنسب مباشرة من نمط Event/State في Bloc لهذه الحالة، ويقلل الكود المكرر بشكل ملموس. Riverpod يعمل أيضًا كـ Dependency Injection Container ذاتيًا (لا حاجة لـ `get_it` منفصل).

## 2. طبقات المعمارية (لكل Feature)

```
features/<feature>/
  data/
    models/          # DTOs — تحويل JSON <-> Dart (freezed + json_serializable)
    repositories/     # تنفيذ فعلي يستخدم SupabaseClient (RPC calls, queries, storage)
  domain/
    entities/         # كيانات العمل النقية (لا تعرف شيئًا عن Supabase)
    repositories/      # Abstract interfaces (يعتمد عليها الـ Domain/Presentation فقط)
    usecases/          # منطق تطبيقي بسيط يغلف استدعاء الـ Repository (اختياري لو العملية بسيطة)
  presentation/
    screens/
    widgets/
    providers/         # Riverpod providers (@riverpod) لهذا الـ Feature
```

**القاعدة:** لا Business Logic في الـ Widgets. أي حساب (مثل تجميع سلة، أو التحقق من صحة نموذج) يعيش في `domain` أو `providers`، والـ UI يكتفي بالعرض والاستدعاء.

الـ Repository Interfaces في `domain` تسمح باستبدال التنفيذ (اختبار بـ Mock) دون لمس الـ UI — هذا هو مبرر الفصل الوحيد المطلوب هنا (وليس Clean Architecture الكاملة بكل طبقاتها الصارمة، لأن حجم المشروع لا يبرر أكثر من هذا الفصل العملي).

## 3. هيكل المجلدات الكامل

```
lib/
  main.dart                       # bootstrap + ProviderScope + Supabase.initialize
  app.dart                        # MaterialApp.router + theme + locale (ar, RTL)

  core/
    config/
      env.dart                    # قراءة --dart-define (SUPABASE_URL, ANON_KEY)
      constants.dart
    router/
      app_router.dart             # go_router + role-based redirect
      route_names.dart
    theme/
      app_theme.dart              # Light + Dark، خطوط عربية (Cairo/Tajawal)
      app_colors.dart
    localization/
      app_ar.arb                  # عربي فقط في v1 (بنية جاهزة لإضافة لغات)
    supabase/
      supabase_client_provider.dart
      realtime_channel_manager.dart
    widgets/                      # عناصر مشتركة: AppButton, AppTextField,
                                   # LoadingView, EmptyView, ErrorView,
                                   # ConfirmDialog, AppScaffold, MoneyText
    utils/
      formatters.dart             # عملة، تاريخ عربي، أرقام
      validators.dart
    errors/
      app_exception.dart          # يحوّل PostgrestException/AuthException
                                   # إلى رسائل عربية مفهومة للمستخدم

  features/
    auth/                         # تسجيل دخول/خروج، تحديد الدور بعد الدخول
    onboarding/                   # شاشات تعريفية أولى (عميل فقط)

    products/                     # كتالوج + تفاصيل منتج + بحث (عميل + أدمن)
    cart/                         # سلة العميل (Local state فقط حتى التأكيد)
    orders/                       # طلبات العميل + إدارة الطلبات (أدمن)

    maintenance/                  # طلب صيانة (عميل) + قائمة/تنفيذ (صنايعي) + متابعة (أدمن)

    technician_bag/                # شنطة الصنايعي (عرض + بيع)
    technician_account/            # حساب الصنايعي + توريد

    inventory/                     # المخزن الرئيسي، حركات المخزون، الجرد (أدمن)
    warehouse_issue/                # صرف بضاعة لصنايعي (أدمن)

    cashbox/                       # الخزنة وحركاتها (أدمن)
    expenses/                       # المصروفات (أدمن)
    customers/                      # إدارة العملاء وحساباتهم (أدمن)
    technicians_admin/              # إدارة الصنايعية (أدمن)

    reports/                        # كل التقارير + Export
    dashboard/                       # لوحة تحكم الأدمن
    notifications/                    # قائمة إشعارات + badge
    audit_log/                        # سجل العمليات (أدمن، قراءة فقط)
    users_admin/                       # إدارة المستخدمين والصلاحيات

  l10n/                                # ملفات ترجمة مولّدة
```

## 4. State Management — أمثلة الاستخدام الفعلي

```dart
// core/supabase/supabase_client_provider.dart
@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) => Supabase.instance.client;

// features/auth/presentation/providers/auth_providers.dart
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}

@riverpod
Future<AppUser?> currentUserProfile(CurrentUserProfileRef ref) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth?.session == null) return null;
  final repo = ref.watch(userRepositoryProvider);
  return repo.getMyProfile();
}

// features/maintenance/presentation/providers/maintenance_queue_provider.dart
@riverpod
Stream<List<MaintenanceRequest>> maintenanceQueue(MaintenanceQueueRef ref) {
  final client = ref.watch(supabaseClientProvider);
  // Realtime subscription على maintenance_requests -> إعادة قراءة الـ view عند أي تغيير
  return client
      .from('maintenance_queue_view')
      .stream(primaryKey: ['id'])
      .order('created_at');
}

@riverpod
Future<MyQueuePosition> myQueuePosition(MyQueuePositionRef ref, String requestId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.rpc('rpc_my_maintenance_position', params: {'p_request_id': requestId});
  return MyQueuePosition.fromJson(res.first);
}
```

كل عملية كتابة حساسة (بيع، صرف، توريد...) في `data/repositories` تستدعي `supabase.rpc('rpc_xxx', params: {...})` فقط — **لا** `insert`/`update` مباشر على جداول الـ Ledger من Flutter إطلاقًا، تطبيقًا حرفيًا لـ `04-security-architecture.md`.

## 5. Routing — `go_router`

- Root redirect بناءً على حالة الجلسة + `role`:
  - غير مسجَّل → `/login`
  - `customer` → `/customer/...` (Shell خاص به)
  - `technician` → `/technician/...`
  - `admin` → `/admin/...`
- Deep Links للإشعارات: `notification.data.order_id` → `/customer/orders/:id`، `notification.data.maintenance_request_id` → الشاشة المناسبة حسب الدور.
- كل Shell (Admin/Technician/Customer) له `StatefulShellRoute` خاص بتبويباته السفلية (Bottom Navigation).

## 6. Dependency Injection

Riverpod نفسه هو الـ DI Container:
```dart
@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) =>
    SupabaseProductRepository(ref.watch(supabaseClientProvider));
```
الاختبار: `ProviderContainer(overrides: [productRepositoryProvider.overrideWithValue(FakeProductRepository())])`.

## 7. Models — `freezed` + `json_serializable`

كل موديل (Product, Order, MaintenanceRequest...) يُبنى بـ `freezed` لضمان Immutability و`copyWith`، مع `fromJson`/`toJson` مطابقة تمامًا لأعمدة الجدول (snake_case في DB يُحوَّل لـ camelCase في Dart عبر `@JsonKey`).

## 8. Realtime Strategy

| البيانات | آلية التحديث |
|---|---|
| قائمة الصيانة (Queue) | `stream()` على `maintenance_queue_view` (يشمل الأدمن/الصنايعي) |
| دور عميل واحد | إعادة استدعاء `rpc_my_maintenance_position` عند أي حدث Realtime على `maintenance_requests` (channel فلترته `customer_id=eq.<id>` غير كافية وحدها لأن الترتيب يعتمد على الكل — لذلك: الاشتراك في حدث عام "أي تغيير بالحالة" ثم إعادة الطلب) |
| حالة الطلب | `stream()` على `orders` مفلترة `customer_id` |
| مخزون شنطة الصنايعي | `stream()` على `technician_bag_stock` مفلترة `technician_bag_id` |
| إشعارات | `stream()` على `notifications` مفلترة `user_id`، Badge count عبر `.length` where `is_read=false` |
| Dashboard الأدمن | Polling كل 30-60 ثانية (Views مجمِّعة، ليست بحاجة Realtime لحظي) أو `stream()` بسيط على `cash_transactions`/`orders` لإعادة حساب الملخصات |

## 9. Error Handling / Loading / Empty States

- كل Repository يُطلق `AppException` موحّد (`AppException.network`, `.unauthorized`, `.insufficientStock`, `.validation(message)`, `.unknown`) بترجمة رسائل PostgREST/RPC الشائعة (مثل `INSUFFICIENT_STOCK`) لرسائل عربية جاهزة.
- كل شاشة تعتمد بيانات غير متزامنة تستخدم `AsyncValue.when(data:, error:, loading:)` من Riverpod مع Widgets موحّدة: `LoadingView`, `ErrorView(onRetry)`, `EmptyView(message, icon)`.
- أي عملية حساسة (بيع، إلغاء، حذف) تمر عبر `ConfirmDialog` قبل التنفيذ.

## 10. Offline / Idempotency على مستوى Flutter

- عمليات البيع/الطلب تُنشئ `clientRequestId = Uuid().v4()` محليًا **قبل** الإرسال، وتُعاد المحاولة بنفس المعرِّف عند الفشل الشبكي (`retry` بنفس الـ UUID) — يطابق `client_request_id` في قاعدة البيانات فيمنع التكرار (راجع NFR-11).
- لا Local Database (لا Hive/SQLite) في v1 — الاعتماد الكامل على اتصال مباشر بـ Supabase مع إعادة محاولة ذكية (`connectivity_plus` لعرض حالة الاتصال + قائمة انتظار بسيطة للطلبات الفاشلة يدويًا من المستخدم). Assumption A9: هذا يكفي لسياق معرض واحد بشبكة WiFi ثابتة غالبًا؛ إن كانت التغطية ضعيفة ميدانيًا (الصنايعي في الشارع) يمكن إضافة Local Queue حقيقية (Isar/Drift) في v2 دون تغيير RPC layer.

## 11. الحزم الأساسية المقترحة (pubspec)

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x
  supabase_flutter: ^2.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  intl: ^0.19.x            # تنسيق عملة/تاريخ عربي
  uuid: ^4.x                # client_request_id
  cached_network_image: ^3.x
  image_picker: ^1.x
  url_launcher: ^6.x         # فتح تطبيق الخرائط
  connectivity_plus: ^6.x
  fl_chart: ^0.69.x           # Charts في Dashboard/التقارير
  pdf: ^3.x / printing: ^5.x  # Export PDF
  syncfusion_flutter_xlsio أو excel: ^4.x  # Export Excel (تقييم عند التنفيذ)

dev_dependencies:
  build_runner
  riverpod_generator
  freezed
  json_serializable
  flutter_lints
```
