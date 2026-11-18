# Implementation Plan: التطبيق يفضل شغال من غير إنترنت

**Branch**: `claude/read-comprehensive-report-d28a04` | **Date**: 2026-11-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-offline-mode/spec.md`

## Summary

التطبيق فيه شغل من غير نت من 2.3.5، بس فيه ثغرات بتخليه يقف: لو بيانات المستخدم ما اتحمّلتش بيرجع لشاشة الدخول، وفيه شاشات قراءة مش داخلة الكاش، والصنايعي والعميل ما عندهمش شريط «مفيش نت»، وبيع الصنايعي وقفل الطلب بيروحوا للسيرفر على طول. الخطة بتبدأ بإعادة المشكلة على الأجهزة، وبعدين بتقفل الثغرات دي بنفس البنية الموجودة (`OfflineHttpClient`، `OfflineSession`، `Outbox`)، ومعاها migration واحدة (`0097`) بتضيف قفل طلب الصيانة لـ `rpc_replay`. التفاصيل في [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3 / Flutter (stable)، و SQL (PostgreSQL على Supabase)

**Primary Dependencies**: `supabase_flutter 2.17.2` (`gotrue 2.27.2`)، Riverpod (riverpod_annotation)، go_router، `http`

**Storage**: على الجهاز: `OfflineStore` (ملفات في application support على أندرويد وويندوز). على السيرفر: Supabase Postgres، ومفيش جداول جديدة

**Testing**: `flutter test` (42 ملف). قاعدة البيانات: `tool/db_tests` على PGlite (`npm test`، 33 مجموعة + `phase36` جديدة)

**Target Platform**: أندرويد وويندوز

**Project Type**: mobile + desktop app على backend مُدار (Supabase)

**Performance Goals**: فتح التطبيق من غير نت لحد الشاشة الرئيسية في أقل من 5 ثواني. وأي شاشة ما تلفش أكتر من 15 ثانية قبل ما تعرض المحفوظ

**Constraints**: ولا عملية فلوس أو مخزن تتسجل مرتين. البيانات المحفوظة متقسمة لكل مستخدم. والصلاحيات تفضل في السيرفر

**Scale/Scope**: 102 شاشة، و4 أدوار، ونوعين عمليات جداد في قائمة الانتظار، و3 RPCs قراءة تدخل الكاش

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` لسه القالب الفاضي، ومفيهوش مبادئ للمشروع، فمفيش بوابات رسمية. اتطبقت بداله قواعد المشروع اللي في الكود:

| القاعدة | الحالة |
|---------|--------|
| أي عملية فلوس أو مخزن تتنفذ في قاعدة البيانات، وتتراجع فيها الصلاحية | ✅ الصلاحية لسه جوه `rpc_complete_maintenance` و`rpc_technician_sale`، و`rpc_replay` بيوزّع بس |
| مفيش عملية تتسجل مرتين | ✅ `client_request_id` للبيع، و`rpc_replay` لقفل الطلب |
| حركات الخزن والمخزن ما بتتعدلش | ✅ مفيش تغيير عليها |
| كل migration ليها اختبار على PGlite | ✅ `phase36_offline_complete_maintenance_test.mjs` |

**بعد التصميم**: نفس النتيجة، ومفيش مخالفات.

## Project Structure

### Documentation (this feature)

```text
specs/001-offline-mode/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── offline-behavior.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── core/
│   ├── offline/
│   │   ├── offline_http_client.dart     # R2: 3 RPCs قراءة تدخل الكاش
│   │   ├── outbox.dart                  # R7: مهلة المحاولة الأولى
│   │   └── offline_widgets.dart         # R3: الشريط وقائمة الانتظار للصنايعي
│   ├── router/auth_redirect.dart        # R1: خطأ نت ≠ شاشة الدخول
│   ├── navigation/
│   │   ├── technician_shell.dart        # R3
│   │   └── customer_shell.dart          # R3
│   ├── errors/app_exception.dart        # R6
│   └── widgets/state_views.dart         # R6: رسالة «هتظهر لما النت يرجع»
└── features/
    ├── auth/                            # R1: حفظ بيانات المستخدم على الجهاز
    ├── technician_account/              # R4: البيع عن طريق Outbox + الشنطة المعروضة
    ├── maintenance/                     # R5: القفل عن طريق Outbox + حالة «في الانتظار» + صور بديلة
    └── cart/ و checkout                 # R6: السلة ما تضيعش

supabase/migrations/
└── 0097_offline_complete_maintenance.sql   # R5

test/                                    # اختبارات Flutter الجديدة
tool/db_tests/
└── phase36_offline_complete_maintenance_test.mjs
```

**Structure Decision**: نفس هيكل المشروع (Flutter features + `core/offline`)، ومفيش مجلدات جديدة غير الـ migration واختبارها.

## خطوات التنفيذ بالترتيب

0. **إعادة المشكلة (R0)**: نشغّل التطبيق بكل دور من غير نت، ونسجّل كل شاشة بتقف، ونتأكد من النسخة اللي على أجهزة المحل. لو طلع سبب مش في الـ research، يتضاف هنا قبل ما نكمل.
1. **P1 — التطبيق يفتح ويفضل شغال**: R1، R2 (ومعاه اختبار التصنيف)، R3، R6، R7.
2. **P1 — المحل**: نتأكد إن الموجود شغال مع المهلة الجديدة (اختبارات `Outbox`).
3. **P2 — الصنايعي**: migration `0097` واختبارها، وبعدين R4 وR5 في التطبيق.
4. **P3 — العميل**: الشريط، ورسالة الطلب، والسلة.
5. **التحقق**: [quickstart.md](quickstart.md) كامل، وبعده نسخة 2.4.0 (أندرويد + ويندوز). وقبل ما النسخة تتنزل، `0097` لازم تتطبق على Supabase.

## Complexity Tracking

مفيش مخالفات.
