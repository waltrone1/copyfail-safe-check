# Copy Fail Safe Check

Read-only Linux safety check for **CVE-2026-31431 / Copy Fail**.

This tool helps administrators check whether the known `algif_aead`-based Copy Fail attack path appears to be mitigated on a Linux system.

The script is designed as a **safe defensive check**. It does **not** run exploit code.

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

- does **not** run exploit code
- does **not** modify the system
- does **not** download additional payloads
- does **not** attempt privilege escalation
- does **not** prove exploitability

It only performs local read-only checks.

Do **not** run public exploit code on production systems.

---

## Quick usage

```bash
git clone https://github.com/waltrone1/copyfail-safe-check.git
cd copyfail-safe-check
chmod +x check-copyfail-safe.sh
./check-copyfail-safe.sh
