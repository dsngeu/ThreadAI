Scan the ThreadAI codebase for security risks related to credentials, API keys, and sensitive data exposure. This project is open-source, so any leaked secret is a public secret.

Perform all checks below and report findings grouped by severity (Critical / High / Medium / Info). For each finding include: file path, line number, the offending snippet (redacted if it looks like a real secret), and a recommended fix.

---

## Checks to Perform

### 1. Hardcoded Secrets (Critical)
Search all `.swift`, `.plist`, `.xcconfig`, `.json`, `.yaml`, `.yml`, `.env` files for:
- Patterns matching API keys: `sk-`, `sk-ant-`, `Bearer `, `api_key`, `apiKey`, `API_KEY`
- Patterns matching secrets: `secret`, `password`, `passwd`, `token`, `private_key`, `privateKey`
- Long alphanumeric strings (≥ 20 chars) assigned to variables with names containing: key, secret, token, password, credential
- Claude/Anthropic key pattern: `sk-ant-api03-`
- OpenAI key pattern: `sk-proj-`, `sk-`
- Any string literal that looks like a JWT (`eyJ...`)

Use grep commands like:
```
grep -rn --include="*.swift" -E "(sk-ant|sk-proj|Bearer |api_key|apiKey|API_KEY|password\s*=\s*\"|secret\s*=\s*\")" ThreadAI/
grep -rn --include="*.xcconfig" -E "(API_KEY|SECRET|TOKEN|PASSWORD)" .
grep -rn --include="*.plist" -E "(key|secret|token|password)" .
```

### 2. UserDefaults for Sensitive Data (High)
Search for `UserDefaults` usage storing anything that could be sensitive:
```
grep -rn --include="*.swift" "UserDefaults" ThreadAI/
```
Flag any `UserDefaults.standard.set` calls where the key name or value context suggests API keys, tokens, passwords, or user credentials. These MUST use Keychain instead.

### 3. Logging Sensitive Data (High)
Search for `print(`, `Logger`, `os_log`, `NSLog` calls that may output sensitive values:
```
grep -rn --include="*.swift" -E "(print\(|Logger\.|os_log|NSLog)" ThreadAI/
```
Flag any log calls near variables named: key, token, secret, password, apiKey, credential, authHeader.

### 4. URL / Network Requests with Embedded Credentials (High)
Search for hardcoded URLs that contain credentials or auth tokens in the URL string itself:
```
grep -rn --include="*.swift" -E "https?://[^\"]*:[^\"]*@" ThreadAI/
```
Also flag any `Authorization` header construction where the value is a hardcoded string literal (not a variable).

### 5. Test Files with Real Credentials (High)
Search test files for anything that looks like a real API key rather than a placeholder:
```
grep -rn --include="*.swift" -E "(sk-ant|sk-proj|sk-[a-zA-Z0-9]{20,})" ThreadAITests/ ThreadAIUITests/
```
Test mocks must use fake/placeholder strings like `"test-api-key"`, `"sk-test-placeholder"`.

### 6. Git-tracked Sensitive Files (High)
Check whether any of these files are tracked by git (they should NOT be):
```
git ls-files | grep -E "(\\.env|\\.xcconfig|Secrets\\.swift|APIKeys\\.swift|Config\\.swift|credentials)"
```
Flag any `.xcconfig` files that define real keys and are committed to the repo.

### 7. Info.plist / Entitlements Leaks (Medium)
```
grep -rn -E "(API|KEY|SECRET|TOKEN|PASSWORD)" ThreadAI/Info.plist ThreadAI/*.entitlements 2>/dev/null
```
Secrets must never live in `Info.plist` or entitlements files since these ship in the app bundle.

### 8. Keychain Usage Audit (Info)
Verify that `KeychainService.swift` is the single point of Keychain access:
```
grep -rn --include="*.swift" "SecItemAdd\|SecItemCopyMatching\|SecItemUpdate\|SecItemDelete\|kSecValueData" ThreadAI/
```
Any Keychain calls outside `Core/Data/Keychain/KeychainService.swift` are a violation.

### 9. Force-Unwrap of Credentials (Medium)
```
grep -rn --include="*.swift" -E "(apiKey|token|password|secret)[^=]*!" ThreadAI/
```
Force-unwrapping credential optionals can crash or expose nil in logs.

### 10. .gitignore Coverage (Info)
Read `.gitignore` and verify it covers:
- `*.xcconfig` files that might hold keys (or at minimum `Secrets.xcconfig`)
- `.env` files
- `APIKeys.swift` / `Secrets.swift` / `Config.swift` patterns
- Any `**/google-services.json` or similar OAuth config files

---

## Output Format

Print a summary header, then sections:

```
=== ThreadAI Security Scan ===

CRITICAL (x findings)
---------------------
[C1] Hardcoded API key
  File: ThreadAI/Core/AIHarness/Providers/ClaudeProvider.swift:42
  Code: let apiKey = "sk-ant-api03-REDACTED"
  Fix:  Load from KeychainService, never hardcode.

HIGH (x findings)
-----------------
...

MEDIUM (x findings)
-------------------
...

INFO (x findings)
-----------------
...

SUMMARY
-------
Total findings: X
Blocking for open-source publish: <list Critical + High>
Recommended before first commit: <actionable list>
```

If no issues are found in a severity tier, print "None found."

End with a one-line verdict: SAFE TO PUBLISH / NEEDS FIXES BEFORE PUBLISHING.
