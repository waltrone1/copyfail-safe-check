# Copy Fail Safe Check

Read-only Linux safety check for **CVE-2026-31431 / Copy Fail**.

This tool helps administrators check whether the known `algif_aead`-based Copy Fail attack path appears to be mitigated on a Linux system.

## Safety

This tool:

- does not run exploit code
- does not modify the system
- does not download anything
- does not attempt privilege escalation

It only performs local read-only checks.

## Usage

```bash
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
