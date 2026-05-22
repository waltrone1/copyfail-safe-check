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
chmod +x copyfail-safe-check.sh
./copyfail-safe-check.sh
```

Or download only the script:

```bash
curl -O https://raw.githubusercontent.com/waltrone1/copyfail-safe-check/main/copyfail-safe-check.sh
chmod +x copyfail-safe-check.sh
./copyfail-safe-check.sh
```

If `curl` is not available:

```bash
wget https://raw.githubusercontent.com/waltrone1/copyfail-safe-check/main/copyfail-safe-check.sh
chmod +x copyfail-safe-check.sh
./copyfail-safe-check.sh
```

## Cleanup after the check

The script is read-only and does not change the system.

If you only cloned this repository to run the check, you can remove it afterwards:

    cd ~
    rm -rf copyfail-safe-check

If you downloaded only the script, you can remove it afterwards:

    rm -f ./copyfail-safe-check.sh

This only removes the check tool itself. It does not undo system updates, mitigations or security settings.

## How to read the result

If you are not sure what the output means, focus on the final result section at the end of the script output.

### All safe

```text
ALL SAFE - NO ACTION REQUIRED
Machine-readable status: OK_MITIGATED
```

The system appears to be protected against the checked Copy Fail attack path.  
No further action is required right now.

### Protected, but reboot required

```text
PROTECTED NOW - REBOOT REQUIRED
Machine-readable status: MITIGATED_REBOOT_REQUIRED
```

The system appears to be protected for now, but a reboot is required so installed kernel or system updates become active.

Recommended action:

```bash
sudo reboot
```

After the reboot, run the check again:

```bash
./copyfail-safe-check.sh
```

### Action required

```text
ACTION REQUIRED - MODULE IS LOADED
```

or:

```text
ACTION REQUIRED - MODULE IS LOADABLE
```

The system should be reviewed and secured.

Recommended action:

- update kernel and relevant packages
- apply vendor-recommended mitigations if needed
- reboot if required
- run this check again afterwards

### Manual review required

```text
MANUAL REVIEW REQUIRED
```

The script could not clearly determine the protection status.  
Review the full output manually.

## References

The following links are provided for background information only.

Do **not** run public exploit code on production systems.

- Copy Fail project page: https://copy.fail/
- Ubuntu CVE page: https://ubuntu.com/security/CVE-2026-31431
- Debian Security Tracker: https://security-tracker.debian.org/tracker/CVE-2026-31431
- CERT-EU advisory: https://cert.europa.eu/publications/security-advisories/2026-005/

## Disclaimer

This tool is a defensive helper for administrators.

It does not guarantee that a system is fully secure. Always follow your Linux distribution vendor's official security advisories and patch guidance.

## Maintainer

Maintained by [@waltrone1](https://github.com/waltrone1).
