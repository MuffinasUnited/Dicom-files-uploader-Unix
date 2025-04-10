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
```
⚙️ Configuration
The script is currently configured with:

```bash
Copy
Edit
WATCH_DIR=" YOUR SOURCE DIRECTORY"
PACS_AET=" YOUR PACS AET "
PACS_HOST=" YOUR PACS IP "
PACS_PORT=104
CALLING_AET=" YOUR SERVER AET "
LOG_FILE="/usr/local/bin/log/dicom_uploaded_files.log"
ERROR_LOG="/usr/local/bin/log/dicom_error_files.log"
INVALID_LOG="/usr/local/bin/log/dicom_invalid_files.log"
BATCH_SIZE=500
MAX_CONCURRENT_JOBS=2
```

📂 Log and Tracking Files
```bash
File	                                        Description
/usr/local/bin/log/dicom_uploaded_files.log	  Successfully uploaded DICOMs
/usr/local/bin/log/dicom_error_files.log	    Files that failed to upload
/usr/local/bin/log/dicom_invalid_files.log	  Invalid or unreadable files
/usr/local/bin/log/upload_count.log	          Files uploaded in the current batch
/usr/local/bin/log/total_count.log	          Cumulative upload count
/usr/local/bin/log/batch_file.log	            File list for the current batch
/usr/local/bin/log/last_processed_marker	    Timestamp marker for batch scanning
```

🔁 How It Works
```bash
Watches a specified directory (WATCH_DIR) for DICOM files.

Skips previously uploaded or invalid files using log files.

Validates DICOM files using dcmftest.

Uploads files using storescu to the configured PACS server.

Uploads run in batches (BATCH_SIZE) with limited concurrency (MAX_CONCURRENT_JOBS).

System load is monitored; uploads pause if load is too high.

Results are logged for auditing and future runs.
```

🧠 Logic Summary
```bash
Uploads only new, valid, unlogged DICOM files.

Uploads are concurrent but controlled.

Progress and state are persisted across reboots.

Automatically skips duplicate or invalid files.
```

📌 Notes
```bash
Requires dcmtk tools for validation and sending DICOM files.

Recommended to mount your image source (e.g., /YOUR SOURCE DIR) on boot.

Tweak BATCH_SIZE or MAX_CONCURRENT_JOBS for performance tuning.

Script is safe to restart — it tracks previously uploaded files persistently.
```

👨‍💻 Maintainer
```bash
This script was written and is maintained by a system administrator working with medical imaging systems and PACS infrastructure and also ChatGPT.

Feel free to open issues or contribute!
```
