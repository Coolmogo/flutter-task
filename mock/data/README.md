# Mock Data

This folder holds JSON fixtures for offline and development usage.
The files are registered as Flutter assets in `pubspec.yaml` and loaded by the app when local `SharedPreferences` data is empty or cannot be decoded.

- `users.json` matches `User`.
- `projects.json` matches `Project` and nested `Stage`.
- `tasks.json` matches `Task` and nested `ActivityLog`.

Activity authors use the current nested user shape:

```json
"author": {
  "id": "john",
  "name": "John Robert",
  "email": "john@sample.com"
}
```

Use `"author": null` for system-generated history entries.
