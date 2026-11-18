# Contract: تصنيف كل طلب للسيرفر من غير نت

كل نداء `rpc('...')` أو `.from(...)` في `lib/` لازم يكون في واحد من التلات أنواع دول. فيه اختبار بيلف على الكود ويتأكد إن مفيش RPC مش متصنفة.

## 1. قراءة متخزنة — بترد من الجهاز من غير نت

- أي `.from(table).select()` (GET على `/rest/v1/`).
- RPC اسمها `rpc_get_*` أو `rpc_my_*`.
- `rpc_effective_prices`، `rpc_browse_products`، `rpc_offer_products`، `rpc_check_service_availability`.
- **جديد**: `rpc_month_report`، `rpc_month_stock`، `rpc_payroll_preview`، `rpc_technician_warehouse_stock`.

لو مفيش نسخة محفوظة: الشاشة تعرض «البيانات دي هتظهر لما النت يرجع» مع زرار إعادة المحاولة.

## 2. كتابة في قائمة الانتظار — بتتحفظ وتتبعت بعدين

| RPC | الطريقة | مين بيستخدمها |
|-----|---------|---------------|
| الـ 13 الموجودين (بيع مباشر، مصروفات، خزن، مشتريات، دفعات، مرتبات، سلف، طلبات) | زي ما هي | أدمن، مبيعات |
| **`rpc_technician_sale`** | `submit` عادي (فيها `p_client_request_id`) | صنايعي |
| **`rpc_complete_maintenance`** | `submit` بـ `viaReplay: true` | صنايعي، أدمن |

`Outbox.submit` بيرجّع واحد من اتنين:
- `OutboxResult.done(data)` — السيرفر رد.
- `OutboxResult.queued()` — اتحفظت. الشاشة تعرض «اتحفظت وهتتبعت لما النت يرجع».

المحاولة الأولى ليها مهلة 15 ثانية. لو انتهت، العملية تتحفظ في الانتظار.

## 3. محتاجة نت — رسالة واضحة من غير ما التطبيق يقف

تسجيل الدخول والتسجيل، طلب أونلاين، طلب صيانة، رفع صور، النسخة الاحتياطية واسترجاعها، إدارة المستخدمين، `rpc_set_my_city`، `rpc_mark_phone_verified`، استلام وبدء وإلغاء طلب صيانة، تحويل بضاعة بين المخزن والشنطة، إرسال جرد الشنطة، تعديل فاتورة الصنايعي.

لو فشلت بخطأ نت: SnackBar بـ «العملية دي محتاجة إنترنت»، والبيانات اللي المستخدم كتبها (السلة، الفورم) تفضل زي ما هي.

## SQL: `rpc_replay` في `0097`

```text
rpc_replay(p_request_id uuid, p_rpc text, p_params jsonb) returns jsonb
  + when 'rpc_complete_maintenance' then
      perform rpc_complete_maintenance((p->>'p_request_id')::uuid, p->>'p_notes');
```

نفس المدخلات والمخرجات. نفس الـ request id مرتين → التانية بترجع `{"replayed": true}` ومش بترمي خطأ.
