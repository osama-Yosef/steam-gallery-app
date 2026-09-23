-- ============================================================================
-- 0069_require_verified_phone_off.sql
--
-- Reverts 0067: no SMS provider (Firebase or otherwise) can send a real
-- message to an arbitrary number without a billing account on file
-- somewhere — that's carrier economics, not a Firebase-specific limit (hit
-- live: Firebase Phone Auth needs the project on its metered "Blaze" plan,
-- even though normal usage stays inside the free quota). Given the choice
-- of adding billing anywhere vs. no SMS gate at all, this project keeps
-- sign-in to phone + password only, same as before 0067 — back to
-- 0031_phone_verification's own default ("Off by default so deploying this
-- breaks nobody").
--
-- sms_autoconfirm (Management API, alongside 0067) stays ON: Supabase must
-- never again attempt its own (paid, and on this project non-functional)
-- SMS at signup regardless of this switch.
-- ============================================================================

update private.app_settings set value = 'false'::jsonb where key = 'require_verified_phone';
