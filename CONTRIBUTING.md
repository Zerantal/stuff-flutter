# Contributing to the "Stuff" App

Thank you for considering contributing to Home Inventory Manager! We welcome improvements across code, documentation, tests, and more.

## How to Contribute

1. **Fork** the repository and **clone** your fork:
   ```bash
   git clone git@github.com:your-username/stuff-flutter.git
   cd stuff-flutter

2. Create a branch for your work:
```bash
    git checkout -b feature/my-feature
```

3. Install dependencies and ensure a clean working state:
```bash
    flutter pub get
    flutter format .
    flutter analyze
```

4. Implement your changes in code or docs.

5. Test your changes:

```bash
    flutter test
```

6. Commit with a clear message following Conventional Commits:
```bash
    git add .
    git commit -m "feat: add search capability"
```

7. Push and open a Pull Request against main:
```bash
    git push origin feature/my-feature
```
Fill in the PR template, describe your changes, and request a review.

##  Branching & Workflow
* Base all work on the main branch.

* Use short-lived feature branches named feature/..., fix/..., or chore/....

* Each PR should target main and pass all CI checks (lint, format, tests).

## Reporting Issues
* To report bugs or request features, open an issue and include:

* A descriptive title.

* Steps to reproduce (for bugs).

* Expected vs. actual behavior.

* Screenshots or logs, if applicable.

Thank you for making Home Inventory Manager better!
