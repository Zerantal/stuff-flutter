# Home Inventory Manager

A Flutter application to catalog, track, and organize your home belongings. Whether it's electronics, furniture, or sentimental items, this app makes inventory management simple and intuitive.

## Features

- **CRUD Items**: Add, edit, and delete items with details like name, category, location, value, and photos. [**PENDING**]
- **Search & Filter**: Quickly find items by name, category, or location. [**PENDING**]
- **Data Import/Export**: Export and import inventory data as JSON for backups or sharing. [**PENDING**]
- **Multi-Backend Support**: Default local SQLite storage, with cloud sync planned for future releases. [**PENDING**]

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.0.0)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)
- An IDE: VS Code, Android Studio, or IntelliJ IDEA with Flutter & Dart plugins

### Installation

1. **Clone the repository**
```bash
   git clone git@github.com:Zerantal/stuff-flutter.git
   cd stuff-flutter
````

2. **Install dependencies**

   ```bash
   flutter pub get
   ```
3. **Run the app**

   * **Mobile (Android/iOS)**

     ```bash
     flutter run
     ```
   * **Web**

     ```bash
     flutter run -d chrome
     ```

## Project Structure

```
stuff-flutter/
├── android/                # Android config and Gradle files
├── ios/                    # iOS Xcode project and settings
├── lib/                    # Dart source code
│   └── main.dart           # App entrypoint
├── test/                   # Unit and widget tests
├── web/                    # Web target assets
├── linux/, macos/, windows/  # Desktop target configs
├── pubspec.yaml            # Dependencies and metadata
├── analysis_options.yaml   # Lint and analysis rules
└── README.md               # Project overview (this file)
```

##Contributing

We welcome contributions! Please review our [Contributing Guide](CONTRIBUTING.md) to get started.

* **Linting**: Configured via analysis_options.yaml with strict strong-mode rules.

* **Formatting**: Enforced by dart format in pre-commit hooks and CI.

* **Testing**: Run `flutter test` to execute unit and widget tests.




## Code of Conduct
Please see our [Code of Conduct](CODE_OF_CONDUCT.md) for guidelines on community standards.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

```
```

