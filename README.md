# Copy Fail Safe Check

Read-only Linux safety check for **CVE-2026-31431 / Copy Fail**.

This tool helps administrators check whether the known `algif_aead`-based Copy Fail attack path appears to be mitigated on a Linux system.

The script is designed as a **safe defensive check**. It does **not** run exploit code.

---

## Important Safety Notice

This repository is for defensive checking only.

This tool:

- does **not** run exploit code
- does **not** modify the system
- does **not** download additional payloads
- does **not** attempt privilege escalation
- does **not** prove exploitability

Do **not** run public exploit code on production systems.

---

## What this tool does

The script checks:

- whether `algif_aead` is currently loaded
- whether `algif_aead` can be loaded via a `modprobe` dry-run
- whether a modprobe block rule exists
- Debian/Ubuntu kernel and `kmod` package status
- whether a reboot is required
- basic RHEL/Rocky/Alma boot parameter hints

At the end, the script prints a clear final result and tells the user what to do next.

---

## What this tool does not do

This tool:

- does **not** exploit CVE-2026-31431
- does **not** modify kernel modules
- does **not** change modprobe configuration
- does **not** install updates
- does **not** reboot the system
- does **not** download or execute remote code

It only performs local read-only checks.

---

## Quick usage

```bash
git clone https://github.com/waltrone1/copyfail-safe-check.git
cd copyfail-safe-check
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
```

---

## Step-by-step usage for non-specialists

This guide assumes you are already logged in to the Linux system you want to check.

### Option 1: Clone the repository

```bash
git clone https://github.com/waltrone1/copyfail-safe-check.git
cd copyfail-safe-check
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
```

### Option 2: Download only the script

If you do not want to clone the full repository, you can download only the script:

```bash
curl -O https://raw.githubusercontent.com/waltrone1/copyfail-safe-check/main/check-copyfail-safe.sh
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
```

If `curl` is not available, use `wget`:

```bash
wget https://raw.githubusercontent.com/waltrone1/copyfail-safe-check/main/check-copyfail-safe.sh
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
```

---

## Optional usage

### Force colored output

Useful for Ansible, CI logs or non-interactive terminals:

```bash
FORCE_COLOR=1 ./check-copyfail-safe.sh
```

### Disable colored output

```bash
NO_COLOR=1 ./check-copyfail-safe.sh
```

### Enable strict exit codes

```bash
STRICT_EXIT_CODES=1 ./check-copyfail-safe.sh
```

---

## Strict exit codes

Strict exit codes are only used when `STRICT_EXIT_CODES=1` is set.

| Exit code | Meaning |
|---:|---|
| 0 | OK / mitigated |
| 1 | mitigated, but reboot required |
| 2 | action required |
| 3 | manual review required |

Example:

```bash
STRICT_EXIT_CODES=1 ./check-copyfail-safe.sh
echo $?
```

---

## How to read the result

At the end of the script you will see a clear result.

---

### All safe

Example result:

```text
ALL SAFE - NO ACTION REQUIRED
Machine-readable status: OK_MITIGATED
```

This means:

- the system appears to be protected against the known Copy Fail attack path
- `algif_aead` is not loaded
- `algif_aead` is blocked by a modprobe rule
- no reboot is required

Action:

```text
Nothing else is required right now.
```

---

### Protected now, but reboot required

Example result:

```text
PROTECTED NOW - REBOOT REQUIRED
Machine-readable status: MITIGATED_REBOOT_REQUIRED
```

This means:

- the system is currently protected by the `algif_aead` block rule
- `algif_aead` is not loaded
- `algif_aead` is blocked
- a reboot is still required so installed kernel/system updates become active

Recommended action:

```bash
sudo reboot
```

After the reboot, run the check again:

```bash
./check-copyfail-safe.sh
```

The expected result after reboot is:

```text
ALL SAFE - NO ACTION REQUIRED
Machine-readable status: OK_MITIGATED
```

---

### Action required: module is loaded

Example result:

```text
ACTION REQUIRED - MODULE IS LOADED
Machine-readable status: ACTION_REQUIRED_MODULE_LOADED
```

This means:

- `algif_aead` is currently loaded
- the known Copy Fail attack path does not appear to be mitigated

Recommended actions:

- update kernel and `kmod` packages
- apply the vendor-recommended mitigation if needed
- reboot the system
- run this check again afterwards

---

### Action required: module is loadable

Example result:

```text
ACTION REQUIRED - MODULE IS LOADABLE
Machine-readable status: ACTION_REQUIRED_MODULE_LOADABLE
```

This means:

- `algif_aead` appears to be loadable
- the known Copy Fail attack path does not appear to be fully mitigated

Recommended actions:

- update kernel and `kmod` packages
- temporarily block `algif_aead` if needed
- reboot the system if kernel/system updates were installed
- run this check again afterwards

---

### Manual review required

Example result:

```text
MANUAL REVIEW REQUIRED
Machine-readable status: REVIEW_REQUIRED_UNCLEAR
```

This means:

- the script could not clearly determine the protection status

Recommended actions:

- review the full script output
- check the kernel version
- check the `modprobe` result
- check whether `algif_aead` is blocked
- check whether a reboot is required

---

## Example output

```text
============================================================
  COPY FAIL CHECK RESULT
============================================================
  ALL SAFE - NO ACTION REQUIRED
============================================================
Result: This system appears to be protected against the known Copy Fail attack path.

You must do the following:
Nothing else is required right now.

Details:
- algif_aead is not loaded.
- algif_aead is blocked by a modprobe rule.
- No reboot is currently required.

------------------------------------------------------------
Machine-readable status: OK_MITIGATED
Read-only note: This script does not run an exploit and does not modify the system.
------------------------------------------------------------
```

---

## Machine-readable status values

| Status | Meaning |
|---|---|
| `OK_MITIGATED` | System appears protected. No immediate action required. |
| `MITIGATED_REBOOT_REQUIRED` | System appears protected, but a reboot should be scheduled. |
| `ACTION_REQUIRED_MODULE_LOADED` | `algif_aead` is currently loaded. Action required. |
| `ACTION_REQUIRED_MODULE_LOADABLE` | `algif_aead` appears loadable. Action required. |
| `REVIEW_REQUIRED_UNCLEAR` | Manual review required. |

---

## Notes for administrators

This script is not an exploitability test.

It checks defensive indicators related to the known `algif_aead`-based Copy Fail attack path.

A clean result means the known checked attack path appears to be mitigated, but administrators should still follow their Linux distribution vendor's official security advisories and patch guidance.

For production systems, the recommended approach is:

1. Do not run public exploit code.
2. Update kernel and relevant packages.
3. Apply vendor-recommended mitigations if needed.
4. Reboot if required.
5. Run this check again.

---

## Ansible example

Copy the script to multiple Linux systems:

```bash
ansible all -b -m copy -a "src=check-copyfail-safe.sh dest=/tmp/check-copyfail-safe.sh mode=0755"
```

Run the check:

```bash
ansible all -b -m shell -a "FORCE_COLOR=0 /tmp/check-copyfail-safe.sh"
```

Show only the most important lines:

```bash
ansible all -b -m shell -a "FORCE_COLOR=0 /tmp/check-copyfail-safe.sh | grep -E 'Host:|Kernel:|COPY FAIL CHECK RESULT|Machine-readable status:'"
```

---

## Requirements

The script uses common Linux tools such as:

- `bash`
- `uname`
- `grep`
- `modprobe`
- `modinfo`
- `lsmod`
- `dpkg-query` and `apt` on Debian/Ubuntu systems
- `grubby` on some RHEL/Rocky/Alma systems

Some checks may be skipped automatically if a tool is not available on the system.

---

## Supported systems

The script is intended for Linux systems.

It includes specific package checks for:

- Debian
- Ubuntu

It also includes basic boot parameter hints for:

- RHEL
- Rocky Linux
- AlmaLinux

Other Linux distributions may still show useful module and reboot information, but package-specific checks may be limited.

---

## References / Background

The following links are provided for background information only.

Do **not** run public exploit code on production systems.  
This repository provides a safe read-only check and does not include exploit code.

- Copy Fail project page: https://copy.fail/
- Ubuntu Security CVE page: https://ubuntu.com/security/CVE-2026-31431
- Debian Security Tracker: https://security-tracker.debian.org/tracker/CVE-2026-31431
- CERT-EU advisory: https://cert.europa.eu/publications/security-advisories/2026-005/

---

## Security policy

Please do not submit:

- exploit code
- weaponized proof-of-concepts
- privilege escalation payloads
- instructions for exploiting production systems

This repository is intended for defensive checking only.

If you report an issue, please remove:

- hostnames
- IP addresses
- usernames
- internal company names
- sensitive log output

---

## Disclaimer

This tool is provided as a defensive helper for administrators.

It does not guarantee that a system is fully secure. Always follow your Linux distribution vendor's official security advisories and patch guidance.

---

## Maintainer

Maintained by [@waltrone1](https://github.com/waltrone1).
