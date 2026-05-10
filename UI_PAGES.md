# Frysquiz — UI Pages Reference

This document describes every screen in the app, what it does, and who can access it.
No design decisions are captured here — only functionality.

---

## Access levels

| Role | Access |
|------|--------|
| **Unauthenticated** | Login, public form links |
| **User** | Home, form fill, groups, profile |
| **Admin** | All user screens + admin area (overview, groups, forms) |
| **Superadmin** | All admin screens + user management |

---

## Unauthenticated screens

### Login (`/login`)

The entry point for all authenticated users.

- Email and password fields with inline validation
- Submit triggers authentication; errors are shown inline below the fields
- On success, routes to `/home` (user role) or `/admin/overview` (admin/superadmin)
- Shows a list of demo test accounts for development convenience

---

### Public Form (`/fill/:formId`)

Allows anyone with a link to fill in a form without logging in.

- Loads a form by ID; shows an error state if the form is not found
- Runs the same question-by-question flow as the authenticated form fill
- No close/back button (no app shell to return to)
- On completion shows a thank-you state with no "go home" action
- Responses are submitted anonymously (no user ID attached)

---

## User area

Regular users see a bottom navigation bar with three tabs: **Hem**, **Grupper**, **Profil**.

### Home (`/home`)

The primary landing screen for regular users.

- Personalised greeting using the user's first name
- Shows a count of available forms in the header
- Scrollable list of form cards the user has access to (forms targeted at their groups or public forms)
- Each card shows: title, description (truncated), target group name, question count, and a "Besvarad" (completed) badge if the user has already submitted a response
- Tapping a card navigates to the form fill screen
- Empty state shown when no forms are available

### Form Fill (`/form/:id`)

Step-by-step interface for answering a form (authenticated version).

- One question displayed at a time with a progress bar and "Question X of Y" counter
- Animated transition between questions
- Supports five question types:
  - **Free text** — multi-line text input
  - **Single choice** — tap to select one option from a list
  - **Multiple choice** — tap to select multiple options from a list
  - **Rating** — row of numbered circle buttons between a min and max value, with optional labels at each end
  - **Yes/No** — two large buttons (Ja / Nej) with icons
- Back and Next/Submit buttons at the bottom
- On final question the button changes to "Skicka in" and submits all answers
- After submission shows a thank-you screen with a button to return to `/home`

### Groups (`/groups`)

Lets users see and join groups.

- "Dina grupper" section: lists all groups the user is currently a member of, showing name, description, and member count
- "Öppna grupper" section: lists open groups the user has not yet joined, with a "Gå med" button on each
- Joining an open group updates membership immediately
- Empty state shown if the user has no groups

### Profile (`/profile`)

Read-only view of the current user's account information.

- Displays avatar (initials), full name, and role badge (Användare / Admin / Superadmin)
- Shows email address and number of groups the user belongs to
- Logout button

---

## Admin area

Admins and superadmins share a different shell with navigation to four sections.
On wide screens (≥ 800 px) a persistent sidebar is shown; on narrow screens a hamburger drawer is used instead.
The "Användare" tab is only visible to superadmins.

### Overview (`/admin/overview`)

Dashboard giving a quick summary of activity.

- Personalised greeting
- Four stat cards: number of groups, number of sent forms, number of draft forms, number of responses on the most recently sent form
- "Senaste enkäter" section: lists the three most recently sent forms, each showing title and response count, tappable to open the form detail
- Superadmin sees all groups; admin sees only groups they belong to

### Forms list (`/admin/forms`)

List of all forms the admin manages.

- Split into two sections: **Skickade** (sent/published) and **Utkast** (drafts), each with a count
- Each card shows title, description, question count, and target audience (public / group names)
- "Ny enkät" button in the app bar navigates to the create form wizard
- Tapping a card opens the form detail screen

### Form detail (`/admin/forms/:id`)

Full view of a single form including its collected responses.

- Shows title, description, and current status (draft or published chip)
- For public or mixed-target forms: displays the shareable URL with a copy-to-clipboard button
- **Publish action**: if the form is a draft, a "Publicera" button changes its status to sent
- **Response summary per question** (shown once responses exist):
  - Free text: each submitted answer shown as a text block
  - Single/multiple choice: horizontal progress bars showing count per option
  - Rating: bar chart showing distribution across values, plus calculated average
  - Yes/No: two side-by-side progress bars showing count and percentage for each

### Create form (`/admin/forms/create`)

Four-step wizard for building and publishing a new form.

A progress bar and step indicator track position through the wizard. Each step must be completed before advancing.

**Step 1 — Detaljer**
- Title field (required)
- Description field (required, multi-line)

**Step 2 — Målgrupp**
- Toggle to make the form publicly accessible via a shareable link
- Checkbox list of available groups; any number can be selected
- Both public and groups can be active simultaneously (resulting in `FormTargetType.both`)

**Step 3 — Frågor**
- List of question editors; at least one required to proceed
- Each question has: question type selector, question text field, and (for choice types) a comma-separated options field
- Questions can be added with "Lägg till fråga" and individually deleted
- Supported question types: Fritext, Enval, Flerval, Betyg, Ja/Nej

**Step 4 — Granska**
- Read-only summary showing title, description, target audience, and all question texts
- Two actions: "Spara utkast" (saves as draft) or "Publicera" (saves and immediately publishes)
- Both actions navigate back to the forms list

### Groups list (`/admin/groups`)

List of groups the admin manages.

- Each card shows: group initial avatar, name, description, member count, and an open/closed status chip
- "Ny grupp" button opens a dialog to create a new group (name, description, open/closed toggle)
- Superadmin sees all groups; admin sees only groups they belong to
- Tapping a card opens the group detail screen

### Group detail (`/admin/groups/:id`)

Manage membership and roles within a single group.

- Shows group name, description, and open/closed chip
- Member list: each row shows avatar (initials), name, and email
- Members with admin role are shown with an "Admin" chip
- For admins/superadmins with edit rights, each member has a context menu:
  - Promote to / demote from group admin
  - Remove from group
- "Lägg till" button opens a dropdown dialog to add any user who is not already a member (only shown for closed groups or when the current user is a superadmin)

### Users (`/admin/users`) — superadmin only

Platform-wide user management.

- Lists every registered user with: initials avatar, name, email, role chip, and chips for each group they belong to
- Each user has an "Ändra roll" button that opens a menu to change their role to Användare / Admin / Superadmin
