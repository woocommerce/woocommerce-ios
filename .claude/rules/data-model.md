# CoreData Model Changes

When making changes to the CoreData data model (adding/removing/modifying entities or attributes in the `.xcdatamodeld`):

1. **Create a new model version**: Copy the current model to a new version (increment the number), make changes there, and update `_XCCurrentVersionName` in `.xccurrentversion` to point to the new model file. This step is critical — forgetting to select the new version in `.xccurrentversion` means the app will still use the old model at runtime.

2. **Update the changelog**: Add an entry at the top of `Modules/Sources/Storage/Model/MIGRATIONS.md` documenting what changed, following the existing format:
   ```
   ## Model NNN (Release X.X.X.X)
   - @username YYYY-MM-DD
     - Added `attributeName` attribute to `EntityName` entity.
   ```

3. **Add a migration test**: Add a test in `Modules/Tests/StorageTests/CoreData/MigrationTests.swift` that verifies the migration from the previous model version to the new one. Follow existing test patterns:
   - Insert data in the source model version
   - Verify the new attribute/entity does NOT exist in the source
   - Migrate to the new model version
   - Verify the new attribute/entity exists with correct defaults
   - Verify new values can be set and saved

4. **Update Storage properties**: Add/modify `@NSManaged` properties in the corresponding `+CoreDataProperties.swift` file.

5. **Run codegen**: Run Sourcery to regenerate Copiable/Fakeable conformances if the affected model conforms to `GeneratedCopiable` or `GeneratedFakeable`.
