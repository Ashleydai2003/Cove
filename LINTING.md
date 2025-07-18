# Linting Requirements for This Project

This project uses **SwiftLint** to enforce code style and quality for all Swift code. Linting is enforced in CI and must pass for all pull requests and merges to `main` or `develop`.

## How to Run SwiftLint

1. **Install SwiftLint** (if not already installed):
   ```sh
   brew install swiftlint
   ```
2. **Run SwiftLint:**
   ```sh
   swiftlint
   ```
   (No longer using `--strict` by default)

## Custom Linting Configuration

We use a custom [`.swiftlint.yml`](./.swiftlint.yml) config file to relax or disable the most problematic rules for this project. The following rules are **disabled**:
- identifier_name
- function_body_length
- type_body_length
- file_length
- todo
- trailing_newline
- vertical_whitespace
- orphaned_doc_comment
- nesting
- comment_spacing
- statement_position
- empty_parentheses_with_trailing_closure
See the [`.swiftlint.yml`](./.swiftlint.yml) file for the full list.

## Key SwiftLint Rules Still Enforced

- **Unused Closure Parameter**: Unused closure parameters must be replaced with `_` in closures.
- **Multiple Closures with Trailing Closure**: Use parentheses for all closure arguments when passing more than one closure.
- Some basic style and safety rules remain enabled.
- You can further customize the rules in `.swiftlint.yml` as needed.

## CI Enforcement

- SwiftLint runs automatically in CI for all PRs and pushes to `main`/`develop`.
- Linting failures will block merges until resolved (but with the relaxed rules, this should be rare).

## Auto-fixing

Some issues (like trailing whitespace) can be auto-fixed with scripts. Others require manual attention.

## Resources
- [SwiftLint Documentation](https://realm.github.io/SwiftLint/)

---

**Please ensure your code passes linting before submitting a PR!** 