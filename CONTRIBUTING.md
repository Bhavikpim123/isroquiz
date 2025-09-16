# Contributing to ISRO Quiz App

We love your input! We want to make contributing to ISRO Quiz App as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Pull Request Process

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Getting Started

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/isroquiz.git
   cd isroquiz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

4. **Make your changes**
   - Follow the [Flutter style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
   - Write clear, readable code
   - Add comments for complex logic
   - Update tests if needed

5. **Test your changes**
   ```bash
   flutter test
   flutter analyze
   ```

6. **Commit your changes**
   ```bash
   git commit -m "Add some amazing feature"
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

8. **Create a Pull Request**

## Code Style

### Dart/Flutter Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` to format your code
- Run `flutter analyze` and fix all issues
- Use meaningful variable and function names
- Add documentation comments for public APIs

### File Structure

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic and API calls
└── widgets/         # Reusable UI components
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Private members**: `_privateVariable`

### State Management

We use [Riverpod](https://riverpod.dev/) for state management:

- Use `StateNotifier` for complex state
- Use `Provider` for simple values
- Use `FutureProvider` for async operations
- Keep providers focused and single-purpose

## Testing Guidelines

### Unit Tests
- Test business logic in services
- Test state management in providers
- Mock external dependencies
- Aim for >80% code coverage

### Widget Tests
- Test UI components in isolation
- Test user interactions
- Test different states (loading, error, success)

### Integration Tests
- Test complete user flows
- Test app navigation
- Test data persistence

## Documentation

- Update README.md if you change functionality
- Add inline documentation for complex code
- Update API documentation if you change interfaces
- Include examples in documentation

## Bug Reports

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/Bhavikpim123/isroquiz/issues).

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Feature Requests

We welcome feature requests! Please:

1. Check if the feature already exists
2. Search existing issues before creating a new one
3. Provide clear description of the feature
4. Explain why this feature would be useful
5. Consider implementation complexity

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Enforcement

Project maintainers are responsible for clarifying the standards of acceptable behavior and are expected to take appropriate and fair corrective action in response to any instances of unacceptable behavior.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to contact the maintainers:

- Email: bhavikpim123@gmail.com
- GitHub Issues: [Create an issue](https://github.com/Bhavikpim123/isroquiz/issues)

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Special thanks in commit messages

Thank you for contributing to ISRO Quiz App! 🚀