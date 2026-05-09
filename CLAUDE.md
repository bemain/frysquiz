# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (requires a connected device or emulator)
flutter run

# Run on a specific device
flutter run -d <device-id>
flutter devices  # list available devices

# Static analysis
flutter analyze
dart format .

# Tests
flutter test
flutter test test/path/to/test.dart  # single test file

# Build
flutter build apk
flutter build ios
```

## Architecture

**Frysquiz** is a Flutter app for creating and distributing quizzes/forms to youth groups. Admins create forms targeting specific groups or the public; regular users fill them in.

### State management
- **Riverpod** (`flutter_riverpod`) is used throughout. The entry point is `ProviderScope` in `main.dart`.
- Providers live in `lib/providers/`. `service_providers.dart` is the single file that wires the data layer to the UI — swapping mock vs. real is done by changing the four provider definitions there.

### Routing
- **GoRouter** (`go_router`) with role-based redirects in `lib/router/app_router.dart`.
- Two shell routes: `UserShell` (regular users at `/home`, `/groups`, `/profile`, `/form/:id`) and `AdminShell` (admins at `/admin/overview`, `/admin/forms`, `/admin/groups`, `/admin/users`).
- `/fill/:formId` is public and bypasses auth (used for anonymous form submissions).
- Route guards enforce role: `user` → `/home`, `admin`/`superadmin` → `/admin/overview`. Only `superadmin` can access `/admin/users`.

### Data layer pattern
Four abstract service interfaces in `lib/core/services/`:
- `AuthService`, `FormService`, `GroupService`, `ResponseService`

Currently wired to mock implementations in `lib/data/mock_*.dart`. Real Supabase implementations should go in `lib/data/supabase_*.dart`. See `SUPABASE_INTEGRATION.md` for the full migration guide.

### Models
`lib/core/models/` contains plain Dart classes with `copyWith`. None have `fromJson`/`toJson` yet — those need to be added before the Supabase integration can be completed (see `SUPABASE_INTEGRATION.md` → Step 4).

### Database
`lib/database.dart` holds the Supabase client. The project URL and anon key are already configured there. Tables: `profiles`, `groups`, `group_members`, `forms` (questions stored as JSONB), `responses` (answers stored as JSONB).

### Roles
`UserRole` enum: `user`, `admin`, `superadmin`. Admins are regional (they only manage groups they belong to); superadmins manage everything including user roles.

## Theme
Primary color is `Color(0xFFD32F2F)` (red). Defined in `lib/app.dart:_buildTheme()`. Material 3 with all key widget themes centralized there — do not hardcode colors elsewhere.
