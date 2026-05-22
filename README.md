# Copy Fail Safe Check

Read-only Linux safety check for **CVE-2026-31431 / Copy Fail**.

This tool checks whether the known `algif_aead`-based Copy Fail attack path appears to be mitigated on a Linux system.

## Safety

This script is defensive only.

It does **not**:

- run exploit code
- modify the system
- download additional payloads
- attempt privilege escalation

Do **not** run public exploit code on production systems.

## Usage

Clone this repository:

```bash
git clone https://github.com/waltrone1/copyfail-safe-check.git
cd copyfail-safe-check
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
```

Or download only the script:

```bash
curl -O https://raw.githubusercontent.com/waltrone1/copyfail-safe-check/main/check-copyfail-safe.sh
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
```

## How to read the result

### All safe

```text
ALL SAFE - NO ACTION REQUIRED
Machine-readable status: OK_MITIGATED
```

Nothing else is required right now.

### Protected, but reboot required

```text
PROTECTED NOW - REBOOT REQUIRED
Machine-readable status: MITIGATED_REBOOT_REQUIRED
```

Schedule a reboot and run the check again:

```bash
sudo reboot
```

After reboot:

```bash
./check-copyfail-safe.sh
```

### Action required

```text
ACTION REQUIRED - MODULE IS LOADED
```

or:

```text
ACTION REQUIRED - MODULE IS LOADABLE
```

Update the system, apply vendor-recommended mitigations if needed, reboot, and run the check again.

### Manual review required

```text
MANUAL REVIEW REQUIRED
```

Review the full output manually.

## References

- Copy Fail project page: https://copy.fail/
- Ubuntu CVE page: https://ubuntu.com/security/CVE-2026-31431
- Debian Security Tracker: https://security-tracker.debian.org/tracker/CVE-2026-31431
- CERT-EU advisory: https://cert.europa.eu/publications/security-advisories/2026-005/

## Disclaimer

This tool is a defensive helper for administrators.  
It does not guarantee that a system is fully secure. Always follow your Linux distribution vendor's official security advisories and patch guidance.

## Maintainer

Maintained by [@waltrone1](https://github.com/waltrone1).
