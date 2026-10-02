

## CAREX Firebase doctor / progress data

The rehabilitation tracking layer uses Cloud Firestore and is driven by authenticated user data and exercise sessions.

Collections created on demand:

- `users` — account/profile data plus `doctorId` for patient-doctor mapping.
- `exercises` — the CAREX exercise catalog synchronized from the app's exercise library.
- `exerciseAssignments` — doctor-to-patient exercise assignments, targets, dates, status and notes.
- `exercise_progress` — actual completed reps, target reps, duration, form score, assignment ID and timestamp.

The patient dashboard calculates overall rehabilitation progress from active doctor assignments and recorded exercise progress. Doctor dashboard values are read from Firestore rather than fixed demo values.

Health/vitals code backed by the existing Realtime Database is intentionally left unchanged.
