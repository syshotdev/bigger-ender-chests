# Build Documentation

This document explains how to build the mod, the version matrix system, and how to manage multiple Minecraft versions.

## Quick Start

### Prerequisites

- Java 21 or higher
- Gradle (or use the included Gradle wrapper)

### Basic Build Commands

**Windows:**
```powershell
# Build for all Minecraft versions
.\build.ps1

# Build for a specific Minecraft version
.\build.ps1 -MinecraftVersion "1.21.8"

# Clean and build
.\build.ps1 -MinecraftVersion "1.21.8" -Clean
```

**Linux/Mac:**
```bash
# Build for all Minecraft versions
bash build.sh

# Build for a specific Minecraft version
bash build.sh -v 1.21.8

# Clean and build
bash build.sh -c -v 1.21.8
```

**Linux note:** In order to run a specific version via `./gradlew runClient`,
you have to first build that version via `build.sh`

### Build Output

Built JAR files are located in `build/libs/` with the naming format:
```
{mod_name}-{mod_version}-{minecraft_version}.jar
```

Example: `biggerenderchests-1.1.0-1.21.8.jar`

## Version Matrix System

This project uses a version matrix system to build for multiple Minecraft versions simultaneously. The configuration is managed through `versions.json`.

### versions.json Structure

The `versions.json` file defines version mappings for each supported Minecraft version. Each entry contains all the dependencies and build tools needed for that specific Minecraft version.

#### Example Entry

```json
{
  "1.21.8": {
    "yarn_mappings": "1.21.8+build.1",
    "loader_version": "0.17.3",
    "fabric_version": "0.134.0+1.21.8",
    "loom_version": "1.7-SNAPSHOT",
    "gradle_version": "8.14",
    "java_version": 21
  }
}
```

#### Field Descriptions

| Field | Description | Example |
|-------|-------------|---------|
| **yarn_mappings** | The Yarn mappings version for the Minecraft version. Format: `{mc_version}+build.{build_number}` | `"1.21.8+build.1"` |
| **loader_version** | The Fabric Loader version required for this Minecraft version | `"0.17.3"` |
| **fabric_version** | The Fabric API version (optional, for reference) | `"0.134.0+1.21.8"` |
| **loom_version** | The Fabric Loom Gradle plugin version | `"1.7-SNAPSHOT"` |
| **gradle_version** | The Gradle version to use for building | `"8.14"` |
| **java_version** | The minimum Java version required | `21` |

### How the Version Matrix Works

#### 1. Build Process

When building with `-Pminecraft_version=<version>`:

1. Gradle reads `versions.json` at build time
2. It extracts the version-specific configuration for that Minecraft version
3. The build system uses these values to:
   - Configure Minecraft and Yarn mappings dependencies
   - Set Fabric Loader version
   - Apply the correct Fabric Loom plugin version
   - Update `fabric.mod.json` with correct version requirements
   - Generate JAR files with version-specific names

#### 2. CI/CD Integration

The GitHub Actions workflows use a matrix strategy:

- **Build Pipeline** (`.github/workflows/build.yml`):
  - Builds all versions in parallel
  - Each matrix job updates `gradle-wrapper.properties` with the correct Gradle version
  - Uploads artifacts per version

- **Release Pipeline** (`.github/workflows/release.yml`):
  - Builds all versions in parallel
  - Collects all built JARs from all matrix jobs
  - Attaches all JARs to a single GitHub release

#### 3. Local Development

- **With build.ps1** (Windows): Automatically handles version matrix
- **With Gradle directly**: Use `-Pminecraft_version=<version>` to build for a specific version
- **Without version parameter**: Uses defaults from `gradle.properties` (currently 1.21.8)

### Adding a New Minecraft Version

#### Step 1: Find Version Information

1. Check [Fabric Development](https://fabricmc.net/develop) for the latest mappings and loader versions
2. Determine compatible Gradle and Loom versions
3. Verify Java version requirements

#### Step 2: Add to versions.json

Add a new entry to `versions.json`:

```json
{
  "1.21.11": {
    "yarn_mappings": "1.21.11+build.4",
    "loader_version": "0.18.4",
    "fabric_version": "0.141.1+1.21.11",
    "loom_version": "1.14-SNAPSHOT",
    "gradle_version": "9.3.0",
    "java_version": 21
  }
}
```

#### Step 3: Update CI/CD Matrix

Add the version to both workflow files:

**`.github/workflows/build.yml`:**
```yaml
strategy:
  matrix:
    minecraft_version: ["1.21.6", "1.21.8", "1.21.9", "1.21.10", "1.21.11"]
```

**`.github/workflows/release.yml`:**
```yaml
strategy:
  matrix:
    minecraft_version: ["1.21.6", "1.21.8", "1.21.9", "1.21.10", "1.21.11"]
```

#### Step 4: Update Documentation

- Update supported versions in `README.md`
- Update this `BUILD.md` if needed
- Update release notes template in release workflow

#### Step 5: Test

1. Test locally: `.\build.ps1 -MinecraftVersion "1.21.11"`
2. Commit and push changes
3. Verify CI/CD builds succeed for the new version

### Updating Existing Versions

To update a version's configuration (e.g., new loader version, updated mappings):

1. **Edit versions.json**: Update the field(s) that changed
   ```json
   {
     "1.21.8": {
       "loader_version": "0.17.4",  // Updated from 0.17.3
       // ... other fields
     }
   }
   ```

2. **Commit and push**: CI/CD will automatically rebuild with new versions

3. **Verify**: Check that builds succeed and artifacts are correct

### Version-Specific Build Output

Each build produces a JAR file with the version in the filename:
- **Format**: `{mod_name}-{mod_version}-{minecraft_version}.jar`
- **Example**: `biggerenderchests-1.1.0-1.21.8.jar`

The built JAR's `fabric.mod.json` is automatically updated with:
- Correct Minecraft version requirement: `"minecraft": ">=1.21.8"`
- Correct Fabric Loader version requirement: `"fabricloader": ">=0.17.3"`

This ensures each JAR file has the correct dependency requirements for its target Minecraft version.

## Build Scripts

### build.ps1 (Windows)

The `build.ps1` script provides a convenient way to build locally with the same process as CI/CD.

**Features:**
- Builds for all versions or a specific version
- Automatically updates Gradle wrapper distribution URL
- Provides build summaries
- Color-coded output

**Usage:**
```powershell
# Build all versions
.\build.ps1

# Build specific version
.\build.ps1 -MinecraftVersion "1.21.8"

# Clean and build
.\build.ps1 -MinecraftVersion "1.21.8" -Clean
```

**Requirements:**
- PowerShell 5.1 or higher
- Optional: `jq` for JSON parsing (falls back to PowerShell if not available)

### release.ps1

The `release.ps1` script creates a Git tag and triggers the release workflow.

**Usage:**
```powershell
.\release.ps1 -Version "1.1.0"
```

This will:
1. Ensure you're on the master branch
2. Pull latest changes
3. Create and push a tag (e.g., `v1.1.0`)
4. Trigger the release workflow which builds all versions and creates a GitHub release

## Troubleshooting

### Version Not Found Error

**Error**: `Minecraft version X not found in versions.json`

**Solution**:
- Ensure the Minecraft version exists in `versions.json`
- Check for typos in the version string (must match exactly, including dots)
- Verify the version is in the CI/CD matrix if building in GitHub Actions

### Build Fails with Wrong Gradle Version

**Error**: Gradle version mismatch or wrapper issues

**Solution**:
- Verify `gradle_version` in `versions.json` is correct
- The CI/CD workflow automatically updates the wrapper
- Locally, you may need to run: `.\gradlew wrapper --gradle-version <version>`
- Or use `build.ps1` which handles this automatically

### Dependency Resolution Errors

**Error**: Cannot resolve dependencies or mappings

**Solution**:
- Check that `yarn_mappings`, `loader_version`, and `fabric_version` are correct
- Verify versions are available in Fabric's Maven repositories
- Check [Fabric Development](https://fabricmc.net/develop) for correct versions
- Ensure your internet connection can reach Maven repositories

### Build Script Fails

**Error**: `build.ps1` script errors

**Solution**:
- Ensure PowerShell execution policy allows scripts: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Check that `versions.json` exists and is valid JSON
- Verify you have Java 21 installed
- Try running Gradle directly: `.\gradlew build -Pminecraft_version=1.21.8`

### CI/CD Build Fails for One Version

**Error**: One version in the matrix fails while others succeed

**Solution**:
- Check the specific version's configuration in `versions.json`
- Verify the version-specific dependencies are correct
- Check if the Minecraft version or mappings are still available
- Review the GitHub Actions logs for the specific failing version

## Advanced Usage

### Building Without Version Matrix

To build using defaults from `gradle.properties` (useful for quick local testing):

```bash
./gradlew build
```

This will use the default Minecraft version (1.21.8) and settings from `gradle.properties`.

### Custom Build Configuration

You can override individual properties:

```bash
./gradlew build -Pminecraft_version=1.21.8 -Pmod_version=1.2.0
```

### Building Specific Tasks

```bash
# Clean build
./gradlew clean build -Pminecraft_version=1.21.8

# Build without tests
./gradlew build -x test -Pminecraft_version=1.21.8

# Only compile (no JAR)
./gradlew classes -Pminecraft_version=1.21.8
```

## Version Compatibility

### Currently Supported Versions

- **1.21.6**: Full support
- **1.21.8**: Full support (default)
- **1.21.9**: Full support
- **1.21.10**: Full support

### Adding Support for New Versions

When a new Minecraft version is released:

1. Check Fabric compatibility and available mappings
2. Add entry to `versions.json` with correct versions
3. Update CI/CD matrix
4. Test locally before committing
5. Update documentation

### Removing Version Support

To stop building for a version:

1. Remove from `versions.json`
2. Remove from CI/CD matrix in both workflow files
3. Update documentation
4. Consider deprecation notice in release notes

## Build Performance

### CI/CD Build Times

- **Single version**: ~2-3 minutes
- **All versions (parallel)**: ~2-3 minutes (limited by slowest version)
- **Release build**: ~3-4 minutes (includes artifact collection)

### Local Build Times

- **Single version**: ~1-2 minutes (depends on hardware)
- **All versions (sequential)**: ~4-8 minutes (4 versions × 2 minutes)

### Optimization Tips

- Use Gradle daemon: `./gradlew build` (daemon enabled by default)
- CI/CD uses `--no-daemon` for consistency
- Gradle caches dependencies per version
- Subsequent builds are faster due to caching

## Related Files

- **versions.json**: Version matrix configuration
- **build.gradle**: Build script with version matrix logic
- **gradle.properties**: Default build properties
- **build.ps1**: Windows build script
- **.github/workflows/build.yml**: CI/CD build pipeline
- **.github/workflows/release.yml**: CI/CD release pipeline


