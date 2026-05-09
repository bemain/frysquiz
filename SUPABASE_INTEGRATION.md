# Supabase Integration Guide — Frysquiz

## Context

The app is fully functional with mock data. The architecture was deliberately built for this swap: four abstract service interfaces (`AuthService`, `FormService`, `GroupService`, `ResponseService`) sit between the UI and data layer. Replacing mock implementations with Supabase ones is a matter of creating four new classes and changing four lines in `service_providers.dart`.

**Already done for you:**
- `supabase_flutter: ^2.8.4` in `pubspec.yaml`
- `lib/database.dart` — Supabase client initialized with your project URL and anon key
- `lib/providers/service_providers.dart` — single file to swap mock → real

---

## Step 1 — Design the Database Schema

Create these tables in Supabase (Dashboard → Table Editor, or use the SQL editor).

### `profiles` table
Stores app user data. Supabase Auth handles passwords/sessions separately; this table extends it.

```sql
create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null,
  email       text not null unique,
  role        text not null default 'user'  -- 'user' | 'admin' | 'superadmin'
);
```

### `groups` table
```sql
create table groups (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text not null default '',
  is_open     boolean not null default false,
  created_at  timestamptz not null default now()
);
```

### `group_members` table (join table — replaces the memberIds/adminIds arrays in the model)
Normalising this makes queries simpler and RLS easier.

```sql
create table group_members (
  group_id    uuid not null references groups(id) on delete cascade,
  user_id     uuid not null references profiles(id) on delete cascade,
  is_admin    boolean not null default false,
  primary key (group_id, user_id)
);
```

### `forms` table
```sql
create table forms (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  description      text not null default '',
  created_by       uuid not null references profiles(id),
  target_type      text not null default 'group',  -- 'group' | 'public' | 'both'
  target_group_ids uuid[] not null default '{}',
  status           text not null default 'draft',  -- 'draft' | 'sent'
  created_at       timestamptz not null default now(),
  questions        jsonb not null default '[]'
);
```

> **Why store questions as JSONB?**
> Questions are always fetched with their form and never queried independently. JSONB avoids an extra join and keeps the schema simple. Each element in the array looks like:
> ```json
> {
>   "id": "q1",
>   "type": "rating",
>   "text": "How happy are you?",
>   "options": [],
>   "rating_min": 1,
>   "rating_max": 6,
>   "rating_min_label": "Not at all",
>   "rating_max_label": "Very much"
> }
> ```

### `responses` table
```sql
create table responses (
  id           uuid primary key default gen_random_uuid(),
  form_id      uuid not null references forms(id) on delete cascade,
  user_id      uuid references profiles(id),  -- nullable = anonymous response
  answers      jsonb not null default '[]',
  submitted_at timestamptz not null default now(),
  unique (form_id, user_id)  -- one response per user per form
);
```

> Each answer in the array looks like one of:
> ```json
> { "question_id": "q1", "text_value": "Great service" }
> { "question_id": "q2", "selected_options": ["Option A"] }
> { "question_id": "q3", "rating_value": 4 }
> { "question_id": "q4", "yes_no_value": true }
> ```

---

## Step 2 — Row Level Security (RLS)

RLS is Supabase's built-in security layer. Without it, **anyone with your anon key can read and write all data**. Enable and configure it for every table.

```sql
alter table profiles      enable row level security;
alter table groups        enable row level security;
alter table group_members enable row level security;
alter table forms         enable row level security;
alter table responses     enable row level security;
```

### Profiles
```sql
-- Anyone authenticated can read profiles (needed for group lookups)
create policy "profiles_select" on profiles
  for select to authenticated using (true);

-- Users can only update their own profile
create policy "profiles_update" on profiles
  for update using (auth.uid() = id);
```

### Groups
```sql
-- Authenticated users can see all groups
create policy "groups_select" on groups
  for select to authenticated using (true);

-- Only admins/superadmins can create groups
create policy "groups_insert" on groups
  for insert to authenticated
  with check (
    exists (select 1 from profiles where id = auth.uid() and role in ('admin','superadmin'))
  );
```

### Group members
```sql
-- Everyone authenticated can see memberships
create policy "group_members_select" on group_members
  for select to authenticated using (true);

-- Group admins, superadmins, or self-join to open groups
create policy "group_members_insert" on group_members
  for insert to authenticated
  with check (
    user_id = auth.uid()  -- self-join (app checks is_open before calling)
    or exists (select 1 from group_members gm
               where gm.group_id = group_id and gm.user_id = auth.uid() and gm.is_admin)
    or exists (select 1 from profiles where id = auth.uid() and role = 'superadmin')
  );
```

### Forms
```sql
-- Users see sent forms targeting their groups or public forms
create policy "forms_select_user" on forms
  for select to authenticated using (
    status = 'sent'
    and (
      target_type in ('public','both')
      or exists (
        select 1 from group_members
        where user_id = auth.uid()
        and group_id = any(target_group_ids)
      )
    )
  );

-- Admins and superadmins see all forms (including drafts)
create policy "forms_select_admin" on forms
  for select to authenticated using (
    exists (select 1 from profiles where id = auth.uid() and role in ('admin','superadmin'))
  );

-- Only admins/superadmins can create, update, delete forms
create policy "forms_write" on forms
  for all to authenticated
  using (exists (select 1 from profiles where id = auth.uid() and role in ('admin','superadmin')))
  with check (exists (select 1 from profiles where id = auth.uid() and role in ('admin','superadmin')));
```

### Responses
```sql
-- Users see their own responses; admins see all
create policy "responses_select" on responses
  for select to authenticated using (
    user_id = auth.uid()
    or exists (select 1 from profiles where id = auth.uid() and role in ('admin','superadmin'))
  );

-- Anyone can submit (including anonymous for public forms)
create policy "responses_insert" on responses
  for insert with check (true);
```

---

## Step 3 — Supabase Auth Setup

Supabase has built-in Auth that handles sessions, JWTs, and refresh tokens — replacing `MockAuthService` cleanly.

**In the Supabase Dashboard:**
1. Authentication → Providers → Email → enable Email/Password
2. Disable "Confirm email" while developing (enable for production)
3. Create users via Dashboard → Authentication → Users

**Add a trigger** so a `profiles` row is created automatically when a user signs up:
```sql
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'Unnamed'),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'user')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
```

When you create users in the Dashboard, pass `name` and `role` in **user metadata** and the trigger populates the profiles row automatically.

---

## Step 4 — Add JSON Serialization to Models

Each model in `lib/core/models/` needs `fromJson` / `toJson` methods to convert between Dart objects and Supabase row maps (`Map<String, dynamic>`).

**`user_model.dart`** — note `groupIds` comes from a separate query, not the profiles table:
```dart
factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: UserRole.values.byName(json['role'] as String),
  groupIds: List<String>.from(json['group_ids'] as List? ?? []),
);
```

**`question_model.dart`** — stored as nested JSONB inside forms:
```dart
factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
  id: json['id'] as String,
  type: QuestionType.values.byName(json['type'] as String),
  text: json['text'] as String,
  options: List<String>.from(json['options'] as List? ?? []),
  ratingMin: (json['rating_min'] as int?) ?? 1,
  ratingMax: (json['rating_max'] as int?) ?? 6,
  ratingMinLabel: json['rating_min_label'] as String?,
  ratingMaxLabel: json['rating_max_label'] as String?,
);

Map<String, dynamic> toJson() => {
  'id': id,
  'type': type.name,
  'text': text,
  'options': options,
  'rating_min': ratingMin,
  'rating_max': ratingMax,
  if (ratingMinLabel != null) 'rating_min_label': ratingMinLabel,
  if (ratingMaxLabel != null) 'rating_max_label': ratingMaxLabel,
};
```

**`form_model.dart`**:
```dart
factory FormModel.fromJson(Map<String, dynamic> json) => FormModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  createdBy: json['created_by'] as String,
  targetType: FormTargetType.values.byName(json['target_type'] as String),
  targetGroupIds: List<String>.from(json['target_group_ids'] as List? ?? []),
  status: FormStatus.values.byName(json['status'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  questions: (json['questions'] as List? ?? [])
      .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> toJson() => {
  // Do NOT include 'id' or 'created_at' — Supabase generates these on insert
  'title': title,
  'description': description,
  'created_by': createdBy,
  'target_type': targetType.name,
  'target_group_ids': targetGroupIds,
  'status': status.name,
  'questions': questions.map((q) => q.toJson()).toList(),
};
```

**`response_model.dart`**:
```dart
// AnswerModel
factory AnswerModel.fromJson(Map<String, dynamic> json) => AnswerModel(
  questionId: json['question_id'] as String,
  textValue: json['text_value'] as String?,
  selectedOptions: json['selected_options'] != null
      ? List<String>.from(json['selected_options'] as List)
      : null,
  ratingValue: json['rating_value'] as int?,
  yesNoValue: json['yes_no_value'] as bool?,
);

Map<String, dynamic> toJson() => {
  'question_id': questionId,
  if (textValue != null) 'text_value': textValue,
  if (selectedOptions != null) 'selected_options': selectedOptions,
  if (ratingValue != null) 'rating_value': ratingValue,
  if (yesNoValue != null) 'yes_no_value': yesNoValue,
};

// ResponseModel
factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
  id: json['id'] as String,
  formId: json['form_id'] as String,
  userId: json['user_id'] as String?,
  answers: (json['answers'] as List? ?? [])
      .map((a) => AnswerModel.fromJson(a as Map<String, dynamic>))
      .toList(),
  submittedAt: DateTime.parse(json['submitted_at'] as String),
);

Map<String, dynamic> toJson() => {
  'form_id': formId,
  if (userId != null) 'user_id': userId,
  'answers': answers.map((a) => a.toJson()).toList(),
};
```

---

## Step 5 — Implement the Four Supabase Services

Create four new files in `lib/data/`. Each implements an existing abstract interface — the Dart compiler will tell you if you miss any method.

### `lib/data/supabase_auth_service.dart`
```dart
class SupabaseAuthService implements AuthService {
  final _client = Database.client;

  @override
  Future<UserModel?> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email, password: password,
    );
    if (res.user == null) return null;
    return _fetchProfile(res.user!.id);
  }

  Future<UserModel?> getCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return _fetchProfile(userId);
  }

  Future<UserModel?> _fetchProfile(String userId) async {
    final profile = await _client
        .from('profiles').select().eq('id', userId).maybeSingle();
    if (profile == null) return null;
    final memberships = await _client
        .from('group_members').select('group_id').eq('user_id', userId);
    final groupIds = (memberships as List)
        .map((m) => m['group_id'] as String).toList();
    return UserModel.fromJson({...profile, 'group_ids': groupIds});
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
```

### `lib/data/supabase_form_service.dart`
```dart
class SupabaseFormService implements FormService {
  final _client = Database.client;

  @override
  Future<List<FormModel>> getAllForms() async {
    final rows = await _client.from('forms').select()
        .order('created_at', ascending: false);
    return (rows as List).map((r) => FormModel.fromJson(r)).toList();
  }

  @override
  Future<List<FormModel>> getFormsForUser(String userId, List<String> groupIds) async {
    // RLS handles visibility — just query sent forms
    final rows = await _client.from('forms').select()
        .eq('status', 'sent').order('created_at', ascending: false);
    return (rows as List).map((r) => FormModel.fromJson(r)).toList();
  }

  @override
  Future<FormModel?> getFormById(String id) async {
    final row = await _client.from('forms').select().eq('id', id).maybeSingle();
    return row == null ? null : FormModel.fromJson(row);
  }

  @override
  Future<FormModel> createForm(FormModel form) async {
    final row = await _client.from('forms').insert(form.toJson()).select().single();
    return FormModel.fromJson(row);
  }

  @override
  Future<FormModel> updateForm(FormModel form) async {
    final row = await _client.from('forms')
        .update(form.toJson()).eq('id', form.id).select().single();
    return FormModel.fromJson(row);
  }

  @override
  Future<void> deleteForm(String id) async {
    await _client.from('forms').delete().eq('id', id);
  }
}
```

### `lib/data/supabase_group_service.dart`
```dart
class SupabaseGroupService implements GroupService {
  final _client = Database.client;

  Future<GroupModel> _buildGroup(Map<String, dynamic> row) async {
    final members = await _client.from('group_members')
        .select('user_id, is_admin').eq('group_id', row['id'] as String);
    final memberIds = (members as List).map((m) => m['user_id'] as String).toList();
    final adminIds = members.where((m) => m['is_admin'] == true)
        .map((m) => m['user_id'] as String).toList();
    return GroupModel.fromJson({...row, 'member_ids': memberIds, 'admin_ids': adminIds});
  }

  @override
  Future<List<GroupModel>> getAllGroups() async {
    final rows = await _client.from('groups').select();
    return Future.wait((rows as List).map((r) => _buildGroup(r)));
  }

  @override
  Future<List<GroupModel>> getGroupsForUser(String userId) async {
    final memberships = await _client.from('group_members')
        .select('group_id').eq('user_id', userId);
    final ids = (memberships as List).map((m) => m['group_id'] as String).toList();
    if (ids.isEmpty) return [];
    final rows = await _client.from('groups').select().inFilter('id', ids);
    return Future.wait((rows as List).map((r) => _buildGroup(r)));
  }

  @override
  Future<GroupModel?> getGroupById(String id) async {
    final row = await _client.from('groups').select().eq('id', id).maybeSingle();
    return row == null ? null : _buildGroup(row);
  }

  @override
  Future<GroupModel> createGroup({
    required String name, required String description,
    required bool isOpen, required String creatorId,
  }) async {
    final row = await _client.from('groups').insert(
        {'name': name, 'description': description, 'is_open': isOpen})
        .select().single();
    await _client.from('group_members').insert(
        {'group_id': row['id'], 'user_id': creatorId, 'is_admin': true});
    return _buildGroup(row);
  }

  @override
  Future<GroupModel> addMember(String groupId, String userId) async {
    await _client.from('group_members')
        .upsert({'group_id': groupId, 'user_id': userId, 'is_admin': false});
    final row = await _client.from('groups').select().eq('id', groupId).single();
    return _buildGroup(row);
  }

  @override
  Future<GroupModel> removeMember(String groupId, String userId) async {
    await _client.from('group_members')
        .delete().eq('group_id', groupId).eq('user_id', userId);
    final row = await _client.from('groups').select().eq('id', groupId).single();
    return _buildGroup(row);
  }

  @override
  Future<GroupModel> setAdminStatus(String groupId, String userId,
      {required bool isAdmin}) async {
    await _client.from('group_members').update({'is_admin': isAdmin})
        .eq('group_id', groupId).eq('user_id', userId);
    final row = await _client.from('groups').select().eq('id', groupId).single();
    return _buildGroup(row);
  }
}
```

### `lib/data/supabase_response_service.dart`
```dart
class SupabaseResponseService implements ResponseService {
  final _client = Database.client;

  @override
  Future<List<ResponseModel>> getResponsesForForm(String formId) async {
    final rows = await _client.from('responses').select().eq('form_id', formId);
    return (rows as List).map((r) => ResponseModel.fromJson(r)).toList();
  }

  @override
  Future<ResponseModel?> getUserResponse(String formId, String userId) async {
    final row = await _client.from('responses').select()
        .eq('form_id', formId).eq('user_id', userId).maybeSingle();
    return row == null ? null : ResponseModel.fromJson(row);
  }

  @override
  Future<ResponseModel> submitResponse(ResponseModel response) async {
    final row = await _client.from('responses')
        .insert(response.toJson()).select().single();
    return ResponseModel.fromJson(row);
  }
}
```

---

## Step 6 — Swap the Providers (Four Lines in One File)

In `lib/providers/service_providers.dart`:

```dart
// Replace:
final authServiceProvider     = Provider<AuthService>((_) => MockAuthService());
final groupServiceProvider    = Provider<GroupService>((_) => MockGroupService());
final formServiceProvider     = Provider<FormService>((_) => MockFormService());
final responseServiceProvider = Provider<ResponseService>((_) => MockResponseService());

// With:
final authServiceProvider     = Provider<AuthService>((_) => SupabaseAuthService());
final groupServiceProvider    = Provider<GroupService>((_) => SupabaseGroupService());
final formServiceProvider     = Provider<FormService>((_) => SupabaseFormService());
final responseServiceProvider = Provider<ResponseService>((_) => SupabaseResponseService());
```

Everything else in the app (UI, routing, all other providers) stays exactly the same.

---

## Step 7 — Session Persistence on App Restart

Supabase Auth stores the JWT in secure storage and restores it automatically. Update `AuthNotifier` in `lib/providers/auth_provider.dart` to load the existing session on startup:

```dart
// Add to AuthNotifier:
Future<void> restoreSession() async {
  final svc = _ref.read(authServiceProvider);
  if (svc is SupabaseAuthService) {
    final user = await svc.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }
}
```

Call `restoreSession()` in `main.dart` after `Database.initialize()` so users stay logged in after closing the app.

---

## Files to Create / Modify

| Action | File |
|--------|------|
| **Create** | `lib/data/supabase_auth_service.dart` |
| **Create** | `lib/data/supabase_form_service.dart` |
| **Create** | `lib/data/supabase_group_service.dart` |
| **Create** | `lib/data/supabase_response_service.dart` |
| **Modify** | `lib/core/models/user_model.dart` — add `fromJson` |
| **Modify** | `lib/core/models/group_model.dart` — add `fromJson` / `toJson` |
| **Modify** | `lib/core/models/form_model.dart` — add `fromJson` / `toJson` |
| **Modify** | `lib/core/models/question_model.dart` — add `fromJson` / `toJson` |
| **Modify** | `lib/core/models/response_model.dart` — add `fromJson` / `toJson` |
| **Modify** | `lib/providers/service_providers.dart` — swap 4 provider lines |
| **Modify** | `lib/providers/auth_provider.dart` — add `restoreSession()` |
| **Modify** | `lib/core/services/auth_service.dart` — add `getCurrentUser()` to interface |

---

## Recommended Implementation Order

1. **SQL in Supabase Dashboard** — create all tables, enable RLS, add policies
2. **Add the `handle_new_user` trigger** — profiles row auto-creates on signup
3. **Create test users** — add emma, bjorn, lucas via Dashboard → Auth → Users (set `name` and `role` in user metadata)
4. **`fromJson`/`toJson` on all models** — get these right before touching services
5. **`SupabaseAuthService`** — nothing else works until login does
6. **`SupabaseFormService`** — test with the admin panel
7. **`SupabaseGroupService`** — test join/leave flows
8. **`SupabaseResponseService`** — test form submission
9. **Swap providers** in `service_providers.dart` — one at a time
10. **Session restore** — add last, once everything else works

---

## Verification Checklist

- [ ] Login as `lucas@frysquiz.se` → home screen shows his assigned forms
- [ ] Login as `bjorn@frysquiz.se` (admin) → admin panel shows drafts + sent forms
- [ ] Submit a form → row appears in `responses` table in Dashboard
- [ ] Create a new form → row appears in `forms` table with correct JSONB questions
- [ ] Publish a draft → `status` changes to `'sent'` in the database
- [ ] Restart the app → user stays logged in (session persistence)
- [ ] Check Dashboard → Authentication → Users → confirm JWT sessions

---

## Gotchas to Watch For

| Issue | Explanation |
|-------|-------------|
| **UUID vs string IDs** | Supabase generates UUID IDs. Your mock uses `"u1"`, `"f1"` etc. Once you insert real rows the IDs will be UUIDs — that's fine, just don't hardcode mock IDs in logic. |
| **RLS silently returning 0 rows** | If a query returns nothing when you expect data, RLS is likely the cause. Test policies in the Dashboard SQL editor, or temporarily disable RLS on a table to confirm. |
| **`group_ids` on UserModel** | The `profiles` table doesn't store group IDs — they come from `group_members`. The service layer merges them before calling `UserModel.fromJson`. |
| **Anonymous responses** | `responses.user_id` is nullable (public form submissions). The RLS insert policy must allow inserts without a matching `auth.uid()`. |
| **Enum name casing** | `QuestionType.values.byName(json['type'])` requires the stored string to exactly match the Dart enum name (e.g., `'freeText'`, not `'free_text'`). Be consistent when inserting. |
| **`toJson` on update calls** | When calling `updateForm`, exclude `id` and `created_at` from the map — or Supabase will try to update those immutable columns. |
