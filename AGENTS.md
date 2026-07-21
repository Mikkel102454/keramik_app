# Flutter client instructions

These instructions apply inside `keramik_app` and supplement the shared `../AGENTS.md`. The shared approval rules remain mandatory.

## Project context

This repository is the Flutter client for the Keramik system. Its main layers are:

- `lib/ui`: pages and reusable widgets;
- `lib/cubits`: authentication and Bloc/Cubit state;
- page controllers using `ChangeNotifier`;
- `lib/repositories`: data access;
- `lib/api`: Dio transport and session-cookie handling;
- `lib/objects`: DTOs and client-side models;
- `lib/config`: application and endpoint configuration.

AutoRoute provides navigation. A shared Dio client and persistent cookie jar communicate with the Spring Boot backend using session authentication.

## Working rules

- Follow the existing feature and layer boundaries unless an approved task changes the architecture.
- Do not introduce another state-management or dependency-injection approach without explicit approval for the dependency and architecture change.
- Keep widgets focused; place network access in repositories and coordination/state in the established controller or Cubit layer.
- Preserve authentication redirects, cookie persistence, and unauthenticated-response handling unless an approved task changes them.
- Treat DTO field names, enum values, multipart fields, endpoint paths, and response handling as shared API contracts. Inspect the backend implementation before changing API-consuming code.
- Do not assume all generated platform targets are supported. Avoid platform-specific behavior unless the target platform is part of the task.
- Do not edit generated files manually. Update the source declaration and use the established generator when generation is required and approved.
- Do not run code generation, `flutter pub get`, or dependency-changing commands if they may update resolved or generated files without first applying the shared approval rules.
- Do not hide or complete placeholder screens unless the requested, approved scope explicitly includes their visible behavior.

## Validation

For relevant changes, prefer:

```powershell
flutter analyze
flutter test
```

Run targeted tests first when available. Report existing analyzer findings separately from findings introduced by the change. If an API-facing change is made, inspect backend compatibility even when the backend is not modified.
