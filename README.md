# 📦 DICOM Uploader Script for PACS

This Bash script automates the process of uploading DICOM files to a PACS server from a watched directory. It uses DCMTK tools (`storescu`, `dcmftest`) to validate and send the files in controlled batches with logging, concurrency control, and system load handling.

---

## ✅ Requirements

### 🛠 Dependencies
Install required packages on **Ubuntu 24.04 LTS**:

```bash
sudo apt update
sudo apt install dcmtk coreutils
```

Tools used:
```bash

storescu and dcmftest (from DCMTK)

find, awk, grep, flock, touch, timeout (standard Unix tools)

systemd (optional for running as a service)
```
