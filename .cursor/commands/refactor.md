# refactor

Execute a comprehensive refactoring of the current context according to our Global Project Rules:

1. **Modularization**: If the file exceeds 300 lines, identify logical subviews or helper classes and propose moving them to separate files.
2. **Standardization**:
   - Apply the mandatory file header (FileName, Project Name, Purpose, Created: dd.mm.yy).
   - Organize the code using // MARK: - State, // MARK: - View Layout, // MARK: - Helpers, // MARK: - Preview.
3. **Swift Idioms**: 
   - Replace any complex logic with modern Swift (Async/Await over closures where possible).
   - Use `guard` statements for early exits.
   - Remove "noisy" or redundant comments.
4. **SwiftUI Polish**: 
   - Ensure there is a working `#Preview`.
   - Use standard Apple spacing and `padding()` instead of hardcoded frames.
   - Verify that all strings are ready for localization (no hardcoded text).

Output: 
- A brief summary of architectural changes.
- The refactored code.
- A "Senior Tip" on how this change improves the app's chance of being featured.
