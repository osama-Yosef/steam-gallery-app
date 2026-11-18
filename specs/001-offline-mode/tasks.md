---
description: "Task list: التطبيق يفضل شغال من غير إنترنت"
---

# Tasks: التطبيق يفضل شغال من غير إنترنت

**Input**: Design documents from `specs/001-offline-mode/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/offline-behavior.md](contracts/offline-behavior.md), [quickstart.md](quickstart.md)

**Tests**: مطلوبة. الخطة وملف التحقق بيطلبوها، وكل migration في المشروع ليها اختبار PGlite. والاختبارات الموجودة اللي هنضيف عليها: `test/outbox_test.dart`، `test/offline_http_client_test.dart`، `test/offline_session_test.dart`، `test/auth_redirect_test.dart`.

**Organization**: المهام متقسمة حسب قصص المستخدم في spec.md: US1 وUS2 (P1)، US3 (P2)، US4 (P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: ممكن تتعمل بالتوازي (ملفات مختلفة، ومفيش اعتماد على مهمة لسه ما خلصتش)
- **[Story]**: القصة اللي المهمة تبعها (US1–US4)

---

## Phase 1: Setup — إعادة المشكلة

**Purpose**: نتأكد من اللي بيحصل فعلًا قبل ما نغيّر حاجة (research R0)

- [ ] T001 شغّل التطبيق على ويندوز (`flutter run -d windows`) بحساب أدمن وحساب صنايعي وحساب عميل. افتح الشاشات الرئيسية والنت شغال، وبعدين افصل النت، واتنقل في كل شاشات القائمة، واقفل التطبيق وافتحه تاني. سجّل كل شاشة بتقف أو بتطلّع خطأ أو بتوديك لشاشة الدخول في `specs/001-offline-mode/repro.md`، ومعاها رقم النسخة المتسطبة على أجهزة المحل (من «عن التطبيق» أو `pubspec.yaml` للنسخة اللي اتبنت). **(لسه — محتاجة تتعمل يدويًا على جهاز من أجهزة المحل، شوف repro.md)**
- [X] T002 قارن `specs/001-offline-mode/repro.md` بأسباب R1–R7 في `specs/001-offline-mode/research.md`. أي سبب جديد يتضاف كـ R9+ في research.md، ومعاه مهمة في القصة المناسبة هنا قبل ما نكمل.

---

## Phase 2: Foundational — حاجات مشتركة بين كل القصص

**Purpose**: رسائل «مفيش نت» ومهلة الكتابة، اللي كل القصص بتعتمد عليها

**⚠️ CRITICAL**: لازم تخلص قبل أي قصة

- [X] T003 [P] في `lib/core/errors/app_exception.dart` ضيف getter `isNetwork` على `AppException` (true لما الخطأ الأصلي `isNetworkError`)، وخلّي رسالة خطأ النت «العملية دي محتاجة إنترنت» بدل «لا يوجد اتصال بالإنترنت». حدّث أي اختبار بيقارن على الرسالة القديمة (`grep -rn "لا يوجد اتصال بالإنترنت" test lib`).
- [X] T004 [P] في `lib/core/widgets/state_views.dart` ضيف لـ `ErrorView` باراميتر اختياري `Object? error`. لو `AppException.from(error).isNetwork`، يعرض أيقونة `Icons.wifi_off` ورسالة «البيانات دي هتظهر لما النت يرجع» بدل `message`، ويفضل زرار إعادة المحاولة. وبعدين مرّر `error` من الأماكن اللي بتستخدم `ErrorView` في `.when(error: (e, _) => ErrorView(...))` (`grep -rn "ErrorView(" lib`). **(اتنفذت بطريقة أبسط: `ErrorView` نفسها بتسمع لـ `NetworkStatus` وبتعرض الرسالة وبتعيد المحاولة لوحدها لما النت يرجع، بدل ما نعدّل 91 مكان)**
- [X] T005 في `lib/core/offline/outbox.dart`، جوه `Outbox.submit`، حط مهلة على المحاولة المباشرة: `_send(entry).timeout(submitTimeout)`، و`submitTimeout` باراميتر في الكونستركتور قيمته الافتراضية `Duration(seconds: 15)`. الـ `TimeoutException` بتتعامل كخطأ نت (`isNetworkError` بيرجع true ليها أصلًا)، فالعملية تتحفظ في الانتظار.
- [X] T006 في `test/outbox_test.dart` ضيف اختبار: RPC وهمية ما بتردش أبدًا، و`submitTimeout` = 50ms → `submit` بيرجّع `OutboxResult.queued()` والعملية في `pending`. وبعد كده الـ RPC ترد → `sync()` يبعتها مرة واحدة.

**Checkpoint**: الأساس جاهز. `flutter test test/outbox_test.dart` ينجح.

---

## Phase 3: User Story 1 — التطبيق يفتح ويفضل شغال لما النت يقطع (Priority: P1) 🎯 MVP

**Goal**: أي دور يفتح التطبيق من غير نت ويوصل لشاشته، ويتنقل في كل الشاشات، من غير ما يقف أو يطلع لشاشة الدخول (FR-001 → FR-006، FR-011 → FR-013)

**Independent Test**: خطوات 1–4 و9 في [quickstart.md](quickstart.md) لكل دور

### Tests for User Story 1

- [X] T007 [P] [US1] في `test/auth_redirect_test.dart` ضيف حالة لـ `ProfileStatus.offline` (جديدة، T010): الجلسة موجودة، `user == null` → `resolveAuthRedirect` يرجّع `Routes.offlineStart` مش `Routes.login`. واتأكد إن `ProfileStatus.error` لسه بيرجّع `Routes.login`.
- [X] T008 [P] [US1] اعمل `test/auth_profile_offline_test.dart`: repository بـ `OfflineStore` في الذاكرة وعميل بيرمي `SocketException`. بعد `getMyProfile` ناجحة مرة، الطلب التاني اللي بيفشل بخطأ نت يرجّع نفس `AppUser` من المحفوظ. ولو المحفوظ لمستخدم تاني، يرمي الخطأ. ولو الخطأ مش خطأ نت (`PostgrestException`)، يرميه ومايرجعش المحفوظ.
- [X] T009 [P] [US1] اعمل `test/offline_rpc_classification_test.dart`: يقرا كل ملفات `lib/**/*.dart`، ويطلّع كل اسم بعد `rpc('` أو `rpc: '`، ويتأكد إن كل اسم في واحدة من التلات قوايم المكتوبة في الاختبار: (1) قراءة متخزنة، والاختبار ده لازم يتأكد كمان إن `OfflineHttpClient.isReadOnlyRpc(name)` بترجع true، (2) كتابة في قائمة الانتظار، (3) محتاجة نت بقصد. القوايم منقولة من [contracts/offline-behavior.md](contracts/offline-behavior.md). أي اسم مش في قايمة → الاختبار يفشل ويقول اسمه.

### Implementation for User Story 1

- [X] T010 [US1] في `lib/core/router/auth_redirect.dart` ضيف `ProfileStatus.offline`، ولما `user == null` و`profileStatus == offline` رجّع `Routes.offlineStart` (لو المكان مش هو). وضيف `Routes.offlineStart` في ملف الـ routes.
- [X] T011 [US1] في `lib/features/auth/data/repositories/auth_repository.dart`، `getMyProfile`: بعد كل نجاح اكتب الصف JSON في `OfflineStore` بمفتاح `profile:<uid>`. ولما يفشل بـ `isNetworkError(e)`، اقرا `profile:<uid>` ورجّع `AppUser.fromRow`. ولو مش موجود، ارمي `AppException` بـ `isNetwork == true`. ده محتاج تمرير `OfflineStore` للـ repository: ضيف `offlineStoreProvider` (override في `lib/main.dart` زي `outboxProvider`)، وحدّث `authRepositoryProvider`.
- [X] T012 [US1] في `lib/core/router/app_router.dart`، جوه الـ `redirect`: لما `profileAsync.hasError` والخطأ `AppException.from(error).isNetwork`، الـ status يبقى `ProfileStatus.offline` مش `error`. وضيف `GoRoute(path: Routes.offlineStart)` لشاشة جديدة `lib/features/auth/presentation/screens/offline_start_screen.dart`: أيقونة `wifi_off`، و«محتاج إنترنت أول مرة عشان نحمّل بياناتك»، وزرار «إعادة المحاولة» بيعمل `ref.invalidate(currentUserProfileProvider)`. كمان الشاشة تسمع لـ `NetworkStatus.instance` وتعيد المحاولة لوحدها لما يبقى online.
- [X] T013 [P] [US1] في `lib/core/offline/offline_http_client.dart` ضيف `rpc_month_report` و`rpc_month_stock` و`rpc_technician_warehouse_stock` لـ `_isReadOnlyRpc`، وخلّيها `static bool isReadOnlyRpc` (public، مع `@visibleForTesting` لو محتاج) عشان T009. وفي `test/offline_http_client_test.dart` ضيف حالة إن `rpc_month_report` بترد من الكاش من غير نت.
- [X] T014 [P] [US1] في `lib/core/navigation/technician_shell.dart` حط `OfflineStatusBar` فوق المحتوى بنفس طريقة `lib/core/navigation/sales_shell.dart`، وخلّي رابط قائمة الانتظار يروح لـ route جديدة للصنايعي بتعرض `OfflineSyncScreen` (ضيفها في `lib/core/router/app_router.dart` جوه فرع الصنايعي، زي السطرين 277 و628).
- [X] T015 [P] [US1] في `lib/core/navigation/customer_shell.dart` حط `OfflineStatusBar` فوق المحتوى من غير رابط قائمة انتظار. لو `OfflineStatusBar` بيطلب route للقائمة إجباري، خلّيه اختياري في `lib/core/offline/offline_widgets.dart`، ولما ما يتبعتش الشريط يعرض «مفيش إنترنت» بس.
- [X] T016 [P] [US1] في `lib/features/maintenance/presentation/widgets/maintenance_image_thumb.dart` و`lib/features/payments/presentation/screens/admin/admin_instapay_review_screen.dart`: لو `createSignedUrl` أو تحميل الصورة فشل بخطأ نت، اعرض مربع رمادي بأيقونة `image_not_supported` بدل الخطأ. **(ما احتاجتش تغيير: الاتنين كانوا بيعرضوا صورة بديلة أصلًا)**
- [ ] T017 [US1] شغّل `flutter test` واتأكد إن T007–T009 وT013 ناجحين. بعد كده نفّذ خطوات 1–4 و9 من [quickstart.md](quickstart.md) على ويندوز بالأدوار الأربعة، وسجّل النتيجة في `specs/001-offline-mode/repro.md` تحت «بعد US1». **(الجزء الآلي اتعمل ونجح؛ التجربة على الجهاز لسه)**

**Checkpoint**: التطبيق ما بيقفش ولا بيطلّعك برة من غير نت، لأي دور. ده الـ MVP.

---

## Phase 4: User Story 2 — المحل يكمل بيع وشغل من غير نت (Priority: P1)

**Goal**: الكاشير والأدمن يكملوا يوم شغل من غير نت، وكل حاجة توصل مرة واحدة (FR-007، FR-008)

**Independent Test**: خطوات 5 و9 و10 في [quickstart.md](quickstart.md) بحساب مبيعات

### Tests for User Story 2

- [X] T018 [P] [US2] في `test/outbox_test.dart` ضيف اختبار SC-005: 50 `submit` بنوع `walk_in_sale` من غير نت → 50 في `pending`. وبعد ما النت يرجع → `sync()` يبعتهم بنفس الترتيب، وكل `id` يتبعت مرة واحدة، حتى لو أول `sync` وقف في النص بخطأ نت عند العملية رقم 20.

### Implementation for User Story 2

- [X] T019 [US2] راجع شاشات المبيعات اللي بتستخدم `OutboxResult` (`grep -rn "\.queued" lib/features`). أي شاشة لما ترجع `queued` لازم تعرض `showSavedOfflineSnack` (`lib/core/offline/offline_widgets.dart` سطر 14) وتقفل الفورم زي النجاح. صلّح أي شاشة بتتعامل مع `queued` كخطأ أو ما بتعرضش حاجة. **(ما احتاجتش تغيير: كل الشاشات بتعرض `showSavedOfflineSnack`)**
- [ ] T020 [US2] نفّذ خطوات 5 و9 و10 من [quickstart.md](quickstart.md) بحساب مبيعات على ويندوز، وسجّل النتيجة في `specs/001-offline-mode/repro.md` تحت «بعد US2». **(لسه — تجربة على الجهاز)**

**Checkpoint**: US1 وUS2 شغالين.

---

## Phase 5: User Story 3 — الصنايعي يكمل شغله في الشارع (Priority: P2)

**Goal**: الصنايعي يبيع من شنطته ويقفل طلب الصيانة من غير نت، والباقي يقول «محتاج إنترنت» (FR-009)

**Independent Test**: خطوات 6 و7 و9 و10 و«حالة رفض» في [quickstart.md](quickstart.md) بحساب صنايعي

### Tests for User Story 3

- [X] T021 [P] [US3] اعمل `tool/db_tests/phase36_offline_complete_maintenance_test.mjs` بنفس شكل `tool/db_tests/phase33_technician_bag_transfer_test.mjs` (`harness.mjs`): صنايعي عليه طلب `in_progress` → `rpc_replay(id, 'rpc_complete_maintenance', {p_request_id, p_notes})` يقفله ويرجّع `replayed: false`. ونفس الـ `id` تاني → `{"replayed": true}` من غير خطأ. وصنايعي تاني مش مسند ليه الطلب → `FORBIDDEN_OR_NOT_IN_PROGRESS`. وضيف `node phase36_offline_complete_maintenance_test.mjs` لآخر سكريبت `test` في `tool/db_tests/package.json`.
- [X] T022 [P] [US3] اعمل `test/technician_offline_test.dart`: (أ) `recordSale` من غير نت بيرجّع queued، والعملية `kind: 'technician_sale'`، و`params['p_client_request_id']` = `entry.id`. (ب) `complete` من غير نت → `kind: 'maintenance_complete'` و`viaReplay: true` و`refId` = رقم الطلب. (ج) كمية الشنطة المعروضة = كمية السيرفر − كميات الصنف في `technician_sale` اللي في الانتظار، وما تقلش عن صفر.

### Implementation for User Story 3

- [X] T023 [US3] اعمل `supabase/migrations/0097_offline_complete_maintenance.sql`: انسخ `create or replace function public.rpc_replay(...)` من آخر نسخة في `supabase/migrations/0081_employees_payroll.sql` زي ما هي، وضيف قبل `else`: `when 'rpc_complete_maintenance' then perform public.rpc_complete_maintenance((p ->> 'p_request_id')::uuid, p ->> 'p_notes');`. وحط فوق الملف تعليق بالشرح زي 0076. شغّل `cd tool/db_tests && npm test`.
- [X] T024 [US3] في `lib/features/technician_account/data/repositories/technician_account_repository.dart`: غيّر `recordSale` بحيث يبعت عن طريق `_outbox.submit(rpc: 'rpc_technician_sale', params: {...نفس الباراميترز}, requestId: clientRequestId, kind: 'technician_sale', refId: maintenanceRequestId, label: 'بيع صنايعي · N أصناف', meta: {items: [{name, qty, price}], total, customerName})`. نوع الرجوع يبقى `Future<String?>` (رقم الفاتورة، أو null لما تتحفظ في الانتظار)، وحدّث الواجهة المجردة في نفس الملف (سطر 33) وكل اللي بينادوها.
- [X] T025 [US3] في `lib/features/maintenance/data/repositories/maintenance_repository.dart`: الـ repository ياخد `Outbox` في الكونستركتور (وحدّث الـ provider بتاعه)، و`complete` يبعت عن طريق `_outbox.submit(rpc: 'rpc_complete_maintenance', params: {'p_request_id': requestId, 'p_notes': notes}, viaReplay: true, kind: 'maintenance_complete', refId: requestId, label: 'قفل طلب صيانة · <اسم العميل>')`، ويرجّع `OutboxResult`.
- [X] T026 [US3] في `lib/features/maintenance/presentation/screens/technician/technician_maintenance_detail_screen.dart`: لو `complete` رجّعت queued، اعرض `showSavedOfflineSnack` وكمّل على فاتورة الصيانة عادي. ولو فيه `outbox.pendingOf('maintenance_complete', refId: requestId)`، اعرض الطلب «اتقفل — في الانتظار» وخبّي زرار «تم التنفيذ».
- [X] T027 [US3] في `lib/features/technician_account/presentation/screens/technician/technician_sale_screen.dart`: لو `recordSale` رجّعت null (في الانتظار)، اعرض `showSavedOfflineSnack` وارجع زي النجاح من غير ما تفتح تفاصيل الفاتورة. وفي `technician_sales_list_screen.dart` اعرض العمليات اللي في `outbox.pendingOf('technician_sale')` فوق القائمة بعلامة «في الانتظار» من `meta`.
- [X] T028 [US3] في `lib/features/inventory/presentation/providers/inventory_providers.dart`، الـ provider اللي بيرجّع `getBagStock(technicianId)` (سطر 41): اطرح من كل صنف مجموع `qty` بتاعه في `outbox.pendingOf('technician_sale')` لنفس الصنايعي (من `params['p_items']`)، وما تقلش عن صفر. والـ provider يتحدث مع `outbox` (`ref.watch(outboxProvider)` أو listener). استخدم نفس طريقة `lib/features/sales/presentation/state/register_stock.dart`.
- [X] T029 [P] [US3] في `technician_bag_transfer_screen.dart`، وشاشة جرد الشنطة، وشاشات استلام وبدء طلب الصيانة، و`technician_sale_edit_screen.dart`: لو العملية فشلت بـ `AppException.isNetwork`، اعرض SnackBar «العملية دي محتاجة إنترنت» وسيب الفورم زي ما هو. **(اتغطت بـ T003: كل الشاشات دي بتعرض `AppException.messageAr`، اللي بقت «العملية دي محتاجة إنترنت» لخطأ النت)**
- [ ] T030 [US3] شغّل `flutter test` و`cd tool/db_tests && npm test`. بعد كده نفّذ خطوات 6 و7 و9 و10 و«حالة رفض» من [quickstart.md](quickstart.md) على أندرويد بحساب صنايعي، بعد ما `0097` تتطبق على قاعدة تجربة. وسجّل النتيجة في `specs/001-offline-mode/repro.md` تحت «بعد US3». **(الجزء الآلي اتعمل ونجح؛ التجربة على أندرويد لسه)**

**Checkpoint**: الصنايعي بيبيع ويقفل طلبات من غير نت.

---

## Phase 6: User Story 4 — العميل يتصفح من غير نت (Priority: P3)

**Goal**: العميل يتصفح المحفوظ، والطلب يقول «محتاج إنترنت» من غير ما السلة تضيع (FR-010)

**Independent Test**: خطوة 8 في [quickstart.md](quickstart.md) بحساب عميل

### Implementation for User Story 4

- [X] T031 [P] [US4] في `lib/features/orders/presentation/screens/customer/checkout_screen.dart`: لو إنشاء الطلب فشل بـ `AppException.isNetwork`، اعرض SnackBar «الطلب محتاج إنترنت، سلتك محفوظة» وما تمسحش السلة ولا تخرج من الشاشة.
- [X] T032 [P] [US4] في `lib/features/cart/presentation/screens/cart_screen.dart` وزرار «أضف للسلة» في `lib/features/products/presentation/screens/customer/product_detail_screen.dart`: لو العملية فشلت بخطأ نت، اعرض «محتاج إنترنت» بدل رسالة الخطأ العامة. وطلب صيانة جديد (`grep -rn "rpc_create_maintenance\|createRequest" lib/features/maintenance/presentation`) يتعامل بنفس الطريقة. **(اتغطت بـ T003 زي T029)**
- [ ] T033 [US4] نفّذ خطوة 8 من [quickstart.md](quickstart.md) بحساب عميل، وسجّل النتيجة في `specs/001-offline-mode/repro.md` تحت «بعد US4». **(لسه — تجربة على الجهاز)**

**Checkpoint**: الأربع قصص شغالين.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T034 [P] حدّث `README.md` (أو `docs/` لو فيه ملف للشغل من غير نت): إيه اللي بيشتغل من غير نت لكل دور، وإيه اللي محتاج نت، وإن `0097` لازم تتطبق قبل النسخة. **(اتعمل في `docs/23-offline-mode.md` بدل README)**
- [X] T035 ارفع النسخة في `pubspec.yaml` لـ `2.4.0+16`.
- [X] T036 شغّل `flutter analyze` و`flutter test` و`cd tool/db_tests && npm test`، وكلهم لازم ينجحوا.
- [ ] T037 نفّذ [quickstart.md](quickstart.md) كله مرة أخيرة (ويندوز + أندرويد، الأدوار الأربعة)، وبعدين ابني نسخة ويندوز بـ `tool/package_windows.ps1`. **(لسه — تجربة على الأجهزة وبناء نسخة ويندوز)**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001–T002)**: من غير اعتماد. ممكن تضيف مهام لو الإعادة طلّعت سبب جديد
- **Foundational (T003–T006)**: بعد Setup، وبتوقف كل القصص
- **US1 (T007–T017)**: بعد Foundational
- **US2 (T018–T020)**: بعد Foundational، ومستقلة عن US1 في الكود. بس التحقق اليدوي محتاج US1 عشان التطبيق يفتح من غير نت
- **US3 (T021–T030)**: بعد Foundational. T014 (شريط الصنايعي) من US1 يفضل يخلص قبل T030
- **US4 (T031–T033)**: بعد Foundational. T015 من US1 يفضل يخلص قبل T033
- **Polish (T034–T037)**: بعد كل القصص

### Within Each Story

- الاختبارات الأول ولازم تفشل، وبعدين التنفيذ
- US1: T010 → T011 → T012 (نفس سلسلة التوجيه)، وT013–T016 بالتوازي
- US3: T023 قبل T030. T024 → T027 → T028 (نفس البيع). T025 → T026 (نفس القفل)

### Parallel Opportunities

- T003 وT004 مع بعض
- T007 وT008 وT009 مع بعض. وT013 وT014 وT015 وT016 مع بعض
- T021 وT022 مع بعض، وT023 بالتوازي مع T024/T025
- T031 وT032 مع بعض

---

## Parallel Example: User Story 1

```text
Task: "T007 حالة ProfileStatus.offline في test/auth_redirect_test.dart"
Task: "T008 test/auth_profile_offline_test.dart"
Task: "T009 test/offline_rpc_classification_test.dart"

Task: "T013 الـ 3 RPCs في offline_http_client.dart"
Task: "T014 الشريط في technician_shell.dart"
Task: "T015 الشريط في customer_shell.dart"
Task: "T016 صورة بديلة في maintenance_image_thumb.dart"
```

## Parallel Example: User Story 3

```text
Task: "T021 tool/db_tests/phase36_offline_complete_maintenance_test.mjs"
Task: "T022 test/technician_offline_test.dart"
Task: "T023 supabase/migrations/0097_offline_complete_maintenance.sql"
```

---

## Implementation Strategy

### MVP First (US1)

1. T001–T002: نعيد المشكلة ونعرف السبب الحقيقي
2. T003–T006: الأساس
3. T007–T017: التطبيق ما يقفش من غير نت
4. **STOP and VALIDATE**: الخطوات 1–4 و9 من quickstart. ممكن نسخة 2.3.10 هنا من غير migration لو محتاجين حل سريع للمحل

### Incremental Delivery

1. US1 → نسخة (من غير migration)
2. US2 → نفس النسخة أو اللي بعدها (من غير migration)
3. US3 → **محتاجة `0097` على Supabase قبل النسخة**
4. US4 → من غير migration
5. Polish → 2.4.0 أندرويد + ويندوز

---

## Notes

- كل commit بعد مهمة أو مجموعة مهام مترابطة
- كل migration بعد `0096` تتطبق على Supabase قبل ما النسخة اللي محتاجاها تتنزل
- ولا عملية فلوس أو مخزن تتسجل مرتين: أي كتابة جديدة في قائمة الانتظار لازم يكون معاها `client_request_id` أو `viaReplay: true`
