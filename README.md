# SHANKARA HEALING MUSIC — Starter v0.2

## Build APK from cloud
This project includes `codemagic.yaml` for a cloud build.
Upload the project to a GitHub repository, connect that repository to Codemagic,
then start the `shankara-android` workflow. The workflow generates Android
platform files, fetches packages, and creates a debug APK.

## Supabase setup
See `supabase/schema.sql`. Configure Supabase URL and anon key before using
login and gallery features. The current starter does not yet configure those
values in the app build.

## Current scope
- Flutter UI shell: music, gallery, account.
- Admin-only photo upload is checked against the Supabase `profiles.role`.
- Per-photo price display.
- Real payment processing, secure original-photo downloads, audio playback,
  and production signing are not implemented yet.

## Important
This is a development starter, not a finished commercial app.
Do not put Supabase service-role keys in the mobile app.
For paid original photos, keep originals in a private bucket and grant access
only after server-side payment verification.
