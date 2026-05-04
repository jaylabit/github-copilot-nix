# github-copilot-nix

Always up-to-date Nix package for [GitHub Copilot CLI](https://github.com/github/copilot-cli) - Copilot coding agent in your terminal.

**Automatically updated hourly** to keep this flake close to the latest GitHub Copilot CLI release.

## Why this package?

### Primary Goal: Always-Up-To-Date GitHub Copilot CLI for Nix Users

While GitHub Copilot CLI can be installed with GitHub's official installer, this flake focuses on:

1. **Immediate Updates**: New GitHub Copilot CLI versions are checked hourly.
2. **Dedicated Maintenance**: A focused repository can react quickly when release packaging changes.
3. **Flake-First Design**: Direct flake usage for NixOS, Home Manager, and `nix profile`.
4. **Native Binary Packaging**: Packages GitHub's official native release tarballs.
5. **Reproducible Pinning**: Version and per-platform hashes are recorded in `sources.json`.

### Why Not Just Use the Official Installer?

GitHub's installer works well for imperative systems:

```bash
curl -fsSL https://gh.io/copilot-install | bash
```

For Nix users, it has the usual limitations of installer-managed software:

- **Not Declarative**: It is not managed by your NixOS or Home Manager configuration.
- **Harder to Pin**: Exact version pinning and rollback are manual.
- **Outside Nix**: The installed binary is not part of the Nix store.
- **Less Reproducible**: Installation depends on mutable external state at install time.

This flake keeps GitHub Copilot CLI in the Nix store with fixed-output hashes while still using GitHub's official release artifacts.

### The Reality of nixpkgs Updates

If `github-copilot-cli` is available in your nixpkgs revision, it is often the best default for broad community review. A dedicated flake is useful when you want a faster update cadence:

- nixpkgs pull requests can take time to review and merge.
- updates depend on maintainer availability.
- you are tied to your nixpkgs channel's update schedule.
- urgent fixes for packaging changes can be delayed.

### This Repository's Approach

This repository provides:

- **Hourly Automated Checks**: GitHub Actions checks for new upstream releases.
- **Pinned Release Artifacts**: `package.nix` fetches GitHub release tarballs with fixed hashes.
- **Multi-Platform Support**: Linux and macOS, x86_64 and aarch64.
- **Simple Update Script**: `scripts/update-version.sh` reads upstream `SHA256SUMS.txt` and updates `sources.json`.
- **Version Tags**: Successful builds create `vX.Y.Z`, `vX`, and `latest` tags.

### Comparison Table

| Feature | Official installer | nixpkgs upstream | This flake |
| --- | --- | --- | --- |
| **Latest Version** | Usually latest | Can lag | Hourly checks |
| **Declarative Config** | No | Yes | Yes |
| **Nix Store Package** | No | Yes | Yes |
| **Version Pinning** | Manual | By nixpkgs revision | Exact tags or commit SHAs |
| **Rollback** | Manual | Nix profile/system rollback | Nix profile/system rollback |
| **Reproducible Fetches** | No | Yes | Yes |
| **Update Frequency** | Immediate | Channel-dependent | Automated hourly check |
| **Broad Review** | GitHub only | nixpkgs review | This repository |

## Quick Start

### Run without installing

```bash
nix run github:jaylabit/github-copilot-nix
```

### Install to your profile

```bash
nix profile install github:jaylabit/github-copilot-nix
```

### Verify installation

```bash
which copilot
copilot --version
```

## Standalone Installation

If you are not using NixOS or Home Manager, use `nix profile`.

### Install

```bash
nix profile install github:jaylabit/github-copilot-nix
```

### Update

```bash
# Update all flake-based profile packages
nix profile upgrade --all

# Or update only GitHub Copilot CLI
nix profile upgrade '.*github-copilot-cli.*'
```

### Rollback

```bash
nix profile rollback
```

### Uninstall

```bash
nix profile remove '.*github-copilot-cli.*'
```

### Troubleshooting PATH

If `copilot` is not found after installation, ensure `~/.nix-profile/bin` is in your `PATH`:

```bash
echo "$PATH" | tr ':' '\n' | grep nix-profile
```

If it is missing, add this to your shell configuration:

```bash
export PATH="$HOME/.nix-profile/bin:$PATH"
```

For multi-user Nix installations, this is typically configured through `/etc/profile.d/nix.sh` or equivalent shell integration.

## Flake Usage

### Using the overlay

```nix
{
  nixpkgs.overlays = [ github-copilot-nix.overlays.default ];
  # pkgs.github-copilot-cli is now available
}
```

### NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    github-copilot-nix.url = "github:jaylabit/github-copilot-nix";
  };

  outputs = { nixpkgs, github-copilot-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ github-copilot-nix.overlays.default ];
          environment.systemPackages = [ pkgs.github-copilot-cli ];
        })
      ];
    };
  };
}
```

### Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    github-copilot-nix.url = "github:jaylabit/github-copilot-nix";
  };

  outputs = { nixpkgs, home-manager, github-copilot-nix, ... }: {
    homeConfigurations."username" =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ github-copilot-nix.overlays.default ];
        };
      in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            home.packages = [ pkgs.github-copilot-cli ];
          }
        ];
      };
  };
}
```

### Direct package reference

```nix
{
  inputs.github-copilot-nix.url = "github:jaylabit/github-copilot-nix";

  outputs = { github-copilot-nix, ... }: {
    packages.x86_64-linux.my-copilot = github-copilot-nix.packages.x86_64-linux.default;
  };
}
```

If you import nixpkgs yourself, remember that this package is unfree:

```nix
import nixpkgs {
  system = "x86_64-linux";
  config.allowUnfree = true;
}
```

## Version Pinning and Update Channels

Choose between immutable pins and moving update channels using git refs.

Only exact version tags such as `v1.0.40` or exact commit SHAs are true pins. `v1`, `latest`, and the default branch are moving refs that intentionally follow newer commits over time.

### Available Refs

| Ref | Example | Behavior | Security Posture |
| --- | --- | --- | --- |
| Exact version tag | `v1.0.40` | Immutable release tag | Best default for reproducible installs |
| Major tag | `v1` | Latest release in that major line | Moving channel, updates over time |
| `latest` tag | `latest` | Newest packaged release | Moving channel, updates over time |
| Default branch | `github:jaylabit/github-copilot-nix` | Tracks repository `main` | Moving channel, fastest updates |

### Usage Examples

```bash
# Always latest from the default branch
nix run github:jaylabit/github-copilot-nix

# Pin to an exact immutable release
nix run github:jaylabit/github-copilot-nix?ref=v1.0.40

# Track latest v1.x
nix run github:jaylabit/github-copilot-nix?ref=v1

# Track the moving latest tag
nix run github:jaylabit/github-copilot-nix?ref=latest
```

### In Flake Inputs

```nix
{
  inputs = {
    # Always latest from the default branch
    github-copilot-nix.url = "github:jaylabit/github-copilot-nix";

    # Pin to an exact immutable release
    github-copilot-nix.url = "github:jaylabit/github-copilot-nix?ref=v1.0.40";

    # Track major version
    github-copilot-nix.url = "github:jaylabit/github-copilot-nix?ref=v1";
  };
}
```

If you use this repository as a flake input, your own `flake.lock` records the resolved commit. Exact tags and commit SHAs give the strongest control; moving refs such as `main`, `v1`, and `latest` only change when you update your lock file.

## Security / Trust Model

This repository is optimized for fast GitHub Copilot CLI updates. That makes the trust model worth stating explicitly.

### What is verified today

- `package.nix` fetches native release tarballs with fixed hashes.
- `sources.json` records the expected version and per-platform hashes.
- `flake.lock` pins flake inputs for a given repository revision.
- CI builds and smoke-tests the package before update PRs land on `main`.
- The updater reads `SHA256SUMS.txt` from the matching upstream release.

### What still requires trust

- Trusting this repo means trusting the maintainer account and the GitHub Actions workflow that creates update PRs.
- The upstream artifacts come from the `github/copilot-cli` release page.
- Moving refs such as `main`, `v1`, and `latest` trade stricter change control for convenience and freshness.

### Recommended setups

| Goal | Recommended Setup |
| --- | --- |
| Highest assurance | Pin an exact commit SHA and review updates manually |
| Balanced default | Pin an exact version tag |
| Fastest updates | Track the default branch, `v1`, or `latest` |

### Forking

Forking is a valid option if you want to fully control update cadence, review upstream diffs yourself, or add additional policy checks before merging updates.

For most users, pinning an exact version tag is simpler and usually enough. A fork only meaningfully improves security if you also add your own review gate instead of automatically tracking upstream.

### Prefer Broader Review Over Speed?

If you prefer a slower update cadence with broader community review, upstream `nixpkgs` may be a better fit than this flake.

## Technical Details

### Package Architecture

- Downloads pre-built native binaries from GitHub Copilot CLI releases.
- Uses the same `copilot-{platform}-{arch}.tar.gz` assets as the official installer.
- Uses `autoPatchelfHook` on Linux for NixOS compatibility.
- Installs the `copilot` binary into `$out/bin/copilot`.
- Keeps release version and hashes in `sources.json`.

### Supported Systems

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Development

```bash
# Clone the repository
git clone https://github.com/jaylabit/github-copilot-nix
cd github-copilot-nix

# Enter development shell
nix develop

# Build the package
nix build

# Run a smoke test
./result/bin/copilot --version

# Check for version updates
./scripts/update-version.sh --check
```

## Updating GitHub Copilot CLI Version

### Automated Updates

This repository uses GitHub Actions to check for new GitHub Copilot CLI versions every hour. When a new version is detected:

1. A pull request is automatically created with the version update.
2. `sources.json` is updated with the new version and hashes for all supported platforms.
3. `flake.lock` is updated.
4. CI runs on Ubuntu and macOS.
5. Version tags are created after successful builds (`vX.Y.Z`, `vX`, `latest`).

The automated update workflow runs:

- every hour
- on manual trigger via the GitHub Actions UI

This workflow is designed for freshness and build validation, not for manual review of every upstream release.

### Manual Updates

#### Using the Update Script

```bash
# Check for updates
./scripts/update-version.sh --check

# Update to latest version
./scripts/update-version.sh

# Update to a specific version
./scripts/update-version.sh --version 1.0.40

# Print latest upstream version
./scripts/update-version.sh --latest-version

# Show help
./scripts/update-version.sh --help
```

The script automatically:

- fetches the latest upstream release version
- reads upstream `SHA256SUMS.txt`
- updates `sources.json`
- updates `flake.lock`
- verifies that the package builds

#### Manual Process

If you prefer to update manually:

1. Edit `sources.json` and change the `version` field.
2. Download `https://github.com/github/copilot-cli/releases/download/vVERSION/SHA256SUMS.txt`.
3. Convert each relevant hex checksum to SRI format with `nix hash convert --hash-algo sha256 --to sri HASH`.
4. Update the matching hash entries in `sources.json`.
5. Run `nix flake update`.
6. Build and test locally: `nix build && ./result/bin/copilot --version`.
7. Submit a pull request.

## Troubleshooting

### `copilot` asks to update

GitHub Copilot CLI may report that a newer version is available. With this flake, updates should happen through Nix:

```bash
nix profile upgrade '.*github-copilot-cli.*'
```

or by updating your flake lock:

```bash
nix flake update github-copilot-nix
```

### `copilot` command not found

Check whether the Nix profile path is available:

```bash
echo "$PATH" | tr ':' '\n' | grep nix-profile
```

If you installed through NixOS or Home Manager, rebuild or switch your configuration and open a new shell.

## Alternatives

### Official Native Install

```bash
curl -fsSL https://gh.io/copilot-install | bash
```

#### Trade-offs

| Aspect | Official Native Install | This Nix Flake |
| --- | --- | --- |
| **Simplicity** | One command | Requires Nix |
| **Official binary** | Yes | Yes |
| **Latest Version** | Usually latest | Hourly checks |
| **Version Pinning** | Manual | Git tags / commit SHAs |
| **Rollback** | Manual | Nix profile/system rollback |
| **Declarative** | No | NixOS/Home Manager |
| **Windows** | Native installer available | Use via WSL or unsupported directly |

Choose the official installer if you want the simplest setup or do not use Nix.

Choose this flake if you use NixOS or Home Manager, want declarative configuration, and are comfortable choosing between exact pins and faster-moving update channels.

## Acknowledgements

This repository is based on the packaging approach from [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix) by [@sadjow](https://github.com/sadjow).

The same author also maintains related Nix package flakes:

- [sadjow/gemini-cli-nix](https://github.com/sadjow/gemini-cli-nix)
- [sadjow/codex-cli-nix](https://github.com/sadjow/codex-cli-nix)

## License

The Nix packaging in this repository is MIT licensed. GitHub Copilot CLI itself is proprietary software by GitHub and subject to its own license terms.
