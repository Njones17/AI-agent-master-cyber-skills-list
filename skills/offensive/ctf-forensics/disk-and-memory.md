# CTF Forensics - Disk and Memory Analysis

## Table of Contents
- [Memory Forensics (Volatility 3)](#memory-forensics-volatility-3)
- [Disk Image Analysis](#disk-image-analysis)
- [VM Forensics (OVA/VMDK)](#vm-forensics-ovavmdk)
- [VMware Snapshot Forensics](#vmware-snapshot-forensics)
- [Coredump Analysis](#coredump-analysis)
- [Deleted Partition Recovery](#deleted-partition-recovery)
- [ZFS Forensics (Nullcon 2026)](#zfs-forensics-nullcon-2026)
- [GPT Partition GUID Data Encoding (VuwCTF 2025)](#gpt-partition-guid-data-encoding-vuwctf-2025)
- [Windows Minidump String Carving (0xFun 2026)](#windows-minidump-string-carving-0xfun-2026)
- [VMDK Sparse Parsing (0xFun 2026)](#vmdk-sparse-parsing-0xfun-2026)
- [Memory Dump String Carving (Pragyan 2026)](#memory-dump-string-carving-pragyan-2026)
- [Memory Dump Malware Extraction + XOR (VuwCTF 2025)](#memory-dump-malware-extraction-xor-vuwctf-2025)
- [Linux Ransomware Memory-Key Recovery (MetaCTF 2026)](#linux-ransomware-memory-key-recovery-metactf-2026)
- [PowerShell Ransomware Analysis](#powershell-ransomware-analysis)

---

## Memory Forensics (Volatility 3)

```bash
vol3 -f memory.dmp windows.info
vol3 -f memory.dmp windows.pslist
vol3 -f memory.dmp windows.cmdline
vol3 -f memory.dmp windows.netscan
vol3 -f memory.dmp windows.filescan
vol3 -f memory.dmp windows.dumpfiles --physaddr <addr>
vol3 -f memory.dmp windows.mftscan | grep flag
```

**Common plugins:**
- `windows.pslist` / `windows.pstree` - Process listing
- `windows.cmdline` - Command line arguments
- `windows.netscan` - Network connections
- `windows.filescan` - File objects in memory
- `windows.dumpfiles` - Extract files by physical address
- `windows.mftscan` - MFT FILE objects in memory (timestamps, filenames). Note: `mftparser` was Volatility 2 only; Vol3 uses `mftscan`

---

## Disk Image Analysis

```bash
# Mount read-only
sudo mount -o loop,ro image.dd /mnt/evidence

# Autopsy / Sleuth Kit
fls -r image.dd              # List files recursively
icat image.dd <inode>        # Extract file by inode

# Carving deleted files
photorec image.dd
foremost -i image.dd
```

---

## VM Forensics (OVA/VMDK)

```bash
# OVA = TAR archive containing VMDK + OVF
tar -xvf machine.ova

# 7z reads VMDK directly (no mount needed)
7z l disk.vmdk | head -100
7z x disk.vmdk -oextracted "Windows/System32/config/SAM" -r
```

**Key files to extract from VM images:**
- `Windows/System32/config/SAM` - Password hashes
- `Windows/System32/config/SYSTEM` - Boot key
- `Windows/System32/config/SOFTWARE` - Installed software
- `Users/*/NTUSER.DAT` - User registry
- `Users/*/AppData/` - Browser data, credentials

---

## VMware Snapshot Forensics

**Converting VMware snapshots to memory dumps:**
```bash
# .vmss (suspended state) + .vmem (memory) → memory.dmp
vmss2core -W path/to/snapshot.vmss path/to/snapshot.vmem
# Output: memory.dmp (analyzable with Volatility/MemprocFS)
```

**Malware hunting in snapshots (Armorless):**
1. Check Amcache for executed binaries near encryption timestamp
2. Look for deceptive names (Unicode lookalikes: `ṙ` instead of `r`)
3. Dump suspicious executables from memory
4. If PyInstaller-packed: `pyinstxtractor` → decompile `.pyc`
5. If PyArmor-protected: use PyArmor-Unpacker

**Ransomware key recovery via MFT:**
- Even if original files deleted, MFT preserves modification timestamps
- Seed-based encryption: recover mtime → derive key
```bash
vol3 -f memory.dmp windows.mftscan | grep flag
# mtime as Unix epoch → seed for PRNG → derive encryption key
```

---

## Coredump Analysis

```bash
gdb -c core.dump
(gdb) info registers
(gdb) x/100x $rsp
(gdb) find 0x0, 0xffffffff, "flag"
```

---

## Deleted Partition Recovery

**Pattern (Till Delete Do Us Part):** USB image with deleted partition table.

**Recovery workflow:**
```bash
# Check for partitions
fdisk -l image.img              # Shows no partitions

# Recover partition table
testdisk image.img              # Interactive recovery

# Or use kpartx to map partitions
kpartx -av image.img            # Maps as /dev/mapper/loop0p1

# Mount recovered partition
mount /dev/mapper/loop0p1 /mnt/evidence

# Check for hidden directories
ls -la /mnt/evidence            # Look for .dotfolders
find /mnt/evidence -name ".*"   # Find hidden files
```

**Flag hiding:** Path components as flag chars (e.g., `/.Meta/CTF/{f/l/a/g}`)

---

## ZFS Forensics (Nullcon 2026)

**Pattern:** Corrupted ZFS pool image with encrypted dataset.

**Recovery workflow:**
1. **Label reconstruction:** All 4 ZFS labels may be zeroed. Find packed nvlist data elsewhere in the image using `strings` + offset searching.
2. **MOS object repair:** Copy known-good nvlist bytes to block locations, recompute Fletcher4 checksums:
```python
def fletcher4(data):
    a = b = c = d = 0
    for i in range(0, len(data), 4):
        a = (a + int.from_bytes(data[i:i+4], 'little')) & 0xffffffff
        b = (b + a) & 0xffffffff
        c = (c + b) & 0xffffffff
        d = (d + c) & 0xffffffff
    return (d << 96) | (c << 64) | (b << 32) | a
```
3. **Encryption cracking:** Extract PBKDF2 parameters (iterations, salt) from ZAP objects. GPU-accelerate with PyOpenCL for PBKDF2-HMAC-SHA1, verify AES-256-GCM unwrap on CPU.
4. **Passphrase list:** rockyou.txt or similar. GPU rate: ~24k passwords/sec.

---

## GPT Partition GUID Data Encoding (VuwCTF 2025)

**Pattern (Undercut):** "LLMs only" + "undercut" → not AI GPT, but GUID Partition Table.

**Key insight:** GPT partition GUIDs are 16 arbitrary bytes — can encode anything. Look for file magic headers in GUIDs.

```bash
# Parse GPT partition table
gdisk -l image.img
# Or with Python:
python3 -c "
import struct
data = open('image.img','rb').read()
# GPT header at LBA 1 (offset 512)
# Partition entries start at LBA 2 (offset 1024)
# Each entry is 128 bytes, GUID at offset 16 (16 bytes)
for i in range(128):
    entry = data[1024 + i*128 : 1024 + (i+1)*128]
    guid = entry[16:32]
    if guid != b'\x00'*16:
        print(f'Partition {i}: {guid.hex()}')
"
```

**First GUID starts with `BZh11AY&SY`** (bzip2 magic) → concatenate GUIDs, decompress as bzip2, then decode ASCII85.

---

## Windows Minidump String Carving (0xFun 2026)

**Pattern (kd):** Go binary crash dump. Flag as plaintext string constant in .data section survives in minidump memory.

```bash
strings -a minidump.dmp | grep -i "flag\|ctf\|0xFUN"
```

**Lesson:** Minidumps contain full memory regions. String constants, keys, and secrets persist. `strings -a` + `grep` is the fast path.

---

## VMDK Sparse Parsing (0xFun 2026)

**Pattern (VMware):** Split sparse VMDK requires grain directory + grain table traversal.

**Key steps:**
1. Parse VMDK sparse header (grain size, GD offset, GT coverage)
2. Follow grain directory → grain table → data grains
3. Calculate absolute disk offsets across split files
4. Mount extracted filesystem (ext4, NTFS)

**Lesson:** Don't assume VM images can be mounted directly. Parse the VMDK sparse format manually.

---

## Memory Dump String Carving (Pragyan 2026)

**Pattern (c47chm31fy0uc4n):** Linux memory dump with flag in environment variables or process data.

```bash
strings -a -n 6 memdump.bin | grep -E "SYNC|FLAG|SSH_CLIENT|SESSION_KEY"
# SSH artifacts reveal source IP and ephemeral port
# Environment variables may contain keys/tokens
```

---

## Memory Dump Malware Extraction + XOR (VuwCTF 2025)

**Pattern (Jellycat):** Extract fake executable from Windows memory dump. Cipher: subtract 0x32, then XOR with cycling key (large multi-line string, e.g., ASCII art).

**Key lesson:** Always extract and reverse the actual binary from memory rather than trusting `strings` output (string tables may be red herrings). XOR keys can be hundreds of bytes (ASCII art, lorem ipsum).

```python
# Extract binary, find XOR key in data section
key = b"..."  # Large ASCII art string
cipher = open('extracted.bin', 'rb').read()
plaintext = bytes((b - 0x32) ^ key[i % len(key)] for i, b in enumerate(cipher))
```

---

## Linux Ransomware Memory-Key Recovery (MetaCTF 2026)

**Pattern:** Linux memory dump + encrypted `.veg` files + `enc_key.bin`; ransomware uses hybrid crypto (AES for files, RSA-wrapped key). Volatility may fail process enumeration due symbol/KASLR mismatch.

**Fast workflow:**
1. **Confirm archive integrity before analysis.**
```bash
unzip -l encrypted_files.zip
# Compare listed files/sizes vs extracted tree; re-extract cleanly if mismatch
unzip -o encrypted_files.zip -d encrypted_full
```

2. **Reverse ransomware binary quickly to identify mode/layout.**
```bash
strings -a ransomware.elf | grep -E "enc_key|EVP_aes|PUBLIC KEY|.veg"
objdump -d ransomware.elf | less
```
- Typical finding: `AES-256-OFB`, IV prepended to each `.veg`, global 32-byte AES key, RSA public key hardcoded.

3. **Try Volatility normally, then pivot immediately if empty/unstable.**
```bash
vol -f memdump.raw linux.pslist
vol -f memdump.raw linux.proc.Maps
vol -f memdump.raw linux.vmayarascan
```
- If Linux plugins return empty/invalid output despite correct banner/symbols, do **raw-memory candidate scanning**.

4. **Recover AES key via anchored candidate scan + magic validation.**
- Use recurring anchor strings in memory (e.g., `/home/.../enc_key.bin`, HOME path).
- Derive candidate offsets near anchors (page-aligned windows).
- Test each 32-byte candidate by decrypting first blocks of multiple `.veg` files and checking magic bytes (`%PDF-`, `PK\x03\x04`, `\x89PNG\r\n\x1a\n`).
- Keep candidates that satisfy multiple independent signatures.

5. **Decrypt full dataset and verify output completeness.**
```bash
# OFB: iv = first 16 bytes, ciphertext starts at +16
# Decrypt all *.veg recursively from a clean extraction directory
```
- Validate recovered file count against zip listing.
- Watch for duplicated mirror trees (e.g., `snap/*/Downloads/...`) and deduplicate logically.

6. **Defend against false flags.**
- Treat metadata-only flags as suspicious until corroborated by challenge context.
- Prefer tokens from primary project artifacts and perform uniqueness checks:
```bash
rg -n -a '[A-Za-z]+CTF\\{[^}]+\\}' recovered_full
pdftotext recovered_full/**/*.pdf - 2>/dev/null | rg '[A-Za-z]+CTF\\{'
```

**Key lessons:**
- Don’t trust a partial/stale extraction tree; re-extract zip cleanly.
- In OFB ransomware, magic-byte validation is a fast key oracle.
- A plausible `CTF{...}` in metadata can be a decoy; confirm with corpus-wide consistency.

---

## PowerShell Ransomware Analysis

**Pattern (Email From Krampus):** PowerShell memory dump + network capture.

**Analysis workflow:**
1. Extract script blocks from minidump:
```bash
python power_dump.py powershell.DMP
# Or: strings powershell.DMP | grep -A5 "function\|Invoke-"
```

2. Identify encryption (typically AES-CBC with SHA-256 key derivation)

3. Extract encrypted attachment from PCAP:
```bash
# Filter SMTP traffic in Wireshark
# Export attachment, base64 decode
```

4. Find encryption key in memory dump:
```bash
# Key often generated with Get-Random, regex search:
strings powershell.DMP | grep -E '^[A-Za-z0-9]{24}$' | sort | head
```

5. Find archive password similarly, decrypt layers
