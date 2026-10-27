# Part 02 tests

Local: `bash -n parts/part-02-identity-access/files/provision-identities`; inspect script before running.

Target RHEL:

```bash
getent passwd labadmin dev01 dev02 hr01 ops01 auditor01
getent group linuxadmins developers hrteam ops projectreaders
id dev01
sudo -l -U labadmin
namei -l /srv/company/{development,hr,operations,projects}
getfacl /srv/company/{development,hr,operations,projects}
sudo -u dev01 touch /srv/company/development/elsm-access-test
sudo -u auditor01 cat /srv/company/development/elsm-access-test
sudo install -o root -g hrteam -m 0640 /dev/null /srv/company/hr/elsm-safe-test.txt
sudo -u dev01 test ! -r /srv/company/hr/elsm-safe-test.txt
sudo -u dev01 test ! -w /srv/company/hr
sudo -u auditor01 test ! -w /srv/company/projects
sudo rm -f -- /srv/company/development/elsm-access-test /srv/company/hr/elsm-safe-test.txt
```

Use only harmless temporary test data. Remove only the files created by the test and verify they are gone. A denied access test should return non-zero for the attempted access and zero for the expected-denial `test !` command. Target tests: NOT RUN.
