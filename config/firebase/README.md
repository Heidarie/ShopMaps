# Firebase environment files

This directory stores local, ignored snapshots of Firebase configuration.
Each snapshot contains the native Firebase files, `firebase.json`, and the
ignored iOS `Secrets.xcconfig` with the Google OAuth URL scheme.

Create snapshots with:

```bash
scripts/save-firebase-environment.sh dev
scripts/save-firebase-environment.sh prod
```

Activate one with:

```bash
scripts/use-firebase-environment.sh dev
scripts/use-firebase-environment.sh prod
```

The `dev/` and `prod/` directories are ignored because they contain
environment-specific Firebase configuration. The production build scripts
activate `prod` automatically before validating and building the application.

`lib/firebase_options.dart` is intentionally not used. Mobile Firebase is
initialized from `google-services.json` and `GoogleService-Info.plist`, which
must remain outside Git.
