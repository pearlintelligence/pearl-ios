# CI/CD Setup — Pearl iOS

Automated testing on every PR, automatic TestFlight deploy on every merge to `main`.

## Architecture

```
PR opened → Run tests (unit + UI)
Merge to main → Run tests → Build → Upload to TestFlight
Manual trigger → Build → Upload to TestFlight
```

## GitHub Secrets Required

Go to **GitHub → pearlintelligence/pearl-ios → Settings → Secrets and variables → Actions**

### App Store Connect API Key
Create at [App Store Connect → Users & Access → Keys](https://appstoreconnect.apple.com/access/api)

| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | Key ID from App Store Connect (e.g., `ABC123DEFG`) |
| `ASC_ISSUER_ID` | Issuer ID from the API Keys page |
| `ASC_KEY_CONTENT` | Base64-encoded `.p8` key file: `base64 -i AuthKey_ABC123.p8` |

### Code Signing (via fastlane match)
| Secret | Description |
|--------|-------------|
| `MATCH_GIT_URL` | Private repo URL for certificates (e.g., `https://github.com/pearlintelligence/ios-certs.git`) |
| `MATCH_PASSWORD` | Encryption password for match certificates |

### Team & API Keys
| Secret | Description |
|--------|-------------|
| `TEAM_ID` | Apple Developer Team ID (10-char string) |
| `ANTHROPIC_API_KEY` | Claude API key for Pearl's AI |
| `ASTROLOGY_API_KEY` | Astrology-API.io key for Swiss Ephemeris |
| `SENTRY_DSN` | Sentry project DSN for crash reporting |

## First-Time Setup

### 1. Create a private certs repo
```bash
# Create a private repo for match certificates
gh repo create pearlintelligence/ios-certs --private
```

### 2. Initialize match
```bash
cd pearl-ios
fastlane match init
# Choose "git" storage
# Enter the ios-certs repo URL
```

### 3. Generate certificates
```bash
# This creates signing certificates + provisioning profiles
fastlane match appstore
# Enter your MATCH_PASSWORD when prompted (save it as a GitHub secret)
```

### 4. Set Team ID in project.yml
Edit `project.yml` and set your Team ID:
```yaml
DEVELOPMENT_TEAM: "YOUR_TEAM_ID"
```

### 5. Add GitHub Secrets
Add all secrets listed above to the repo settings.

### 6. Push to main
```bash
git push origin main
```
The deploy workflow triggers automatically.

## Local Development

```bash
# Install tools
brew install xcodegen
gem install fastlane

# Generate Xcode project
xcodegen generate

# Open in Xcode
open Pearl.xcodeproj

# Run tests locally
fastlane test

# Deploy to TestFlight locally (requires signing)
fastlane beta
```

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `ci.yml` | PR + push to main | Full build verification with XcodeGen |
| `test.yml` | PR + push to main | Runs unit tests + UI tests |
| `deploy-testflight.yml` | Push to main + manual | Builds, signs, uploads to TestFlight |

## Adding the CI Workflow

A recommended build-verification workflow is included as `ci.yml.recommended` in the repo root.

The GitHub App cannot create workflow files directly — this must be done manually:

```bash
mkdir -p .github/workflows
cp ci.yml.recommended .github/workflows/ci.yml
git add .github/workflows/ci.yml
git commit -m "ci: add build verification workflow"
git push
```

## Manual Deploy

You can trigger a TestFlight deploy anytime from GitHub:
1. Go to **Actions** → **🚀 Deploy to TestFlight**
2. Click **Run workflow**
3. Select branch → **Run**
