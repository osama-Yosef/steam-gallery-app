-- ============================================================================
-- 0067_require_verified_phone.sql
--
-- Turns on what 0031_phone_verification.sql built but left off by default.
-- Paired with two changes made outside this migration (not SQL, so noted
-- here for the record):
--   * Supabase Auth's "sms_autoconfirm" was switched on via the Management
--     API — signUp() now creates the account immediately, with no SMS from
--     Supabase's own (paid, and on this project not even working) provider.
--   * Phone verification itself moved to Firebase Phone Auth (free) — see
--     core/firebase/firebase_phone_auth_service.dart and the
--     verify-phone-firebase Edge Function.
-- With both of those in place, this flag is what actually gates an
-- unverified customer (auth_role(), 0031) until they clear
-- VerifyPhoneScreen, which the router already sends them to automatically
-- (requireVerifiedPhone in auth_redirect.dart).
-- ============================================================================

update private.app_settings set value = 'true'::jsonb where key = 'require_verified_phone';
