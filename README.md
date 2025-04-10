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
