# Part 03 tests

Local: `bash -n parts/part-03-storage/files/validate-storage`; `--help` is safe.

Target RHEL: run the read-only validator with appropriate privileges. Confirm the reported PV/VG/LV and XFS mount are the intended added data storage. Verify the UUID fstab entry with `findmnt --verify`, then reboot and repeat. Do not validate by formatting or injecting data into the OS disk. Target tests: NOT RUN.

