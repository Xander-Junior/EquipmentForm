# ADR-0002: SQLCipher Rollout Plan

- **Status**: Proposed
- **Date**: 2025-10-02

## Context
The Drift database currently stores session payloads (including PERSON/DEVICE metadata) in plaintext SQLite. Milestone 3 requires encrypting on-device storage while preserving offline access and backwards compatibility with existing sessions.

## Decision
Adopt a phased rollout for SQLCipher integration:

1. **M3 implementation**
   - Introduce `sqlcipher_flutter_libs` and expose a migration flag via `SecureStore`.
   - On first launch post-upgrade, create a new encrypted database file (`session_encrypted.sqlite`), copy existing plaintext rows into the encrypted store, then securely delete the old file and pointer.
   - Derive the cipher key from the platform Keychain/Keystore, versioned to allow future key rotation.
2. **Fallback & resilience**
   - If the encrypted open fails (e.g., corrupted file), fall back to read-only plaintext import with user prompt to re-capture if migration cannot succeed.
   - Maintain schema parity between plaintext and encrypted DBs to minimize migration risk.
3. **Observability**
   - Log migration success/failure via local analytics table for diagnostics (no PII).
4. **Testing**
   - Provide integration tests covering cold-start migration, corrupted plaintext, and corrupted encrypted file recovery.

## Consequences
- Requires bundling SQLCipher native libs, increasing binary size slightly.
- Migration path must be idempotent to handle app restarts during encryption.
- Future schema changes must be applied to both plaintext (for migration) and encrypted paths until legacy installs are exhausted.

## Follow-up
- Implement migration + key management utilities in Milestone 3.
- Update runbook/README with recovery procedures for failed migrations.
