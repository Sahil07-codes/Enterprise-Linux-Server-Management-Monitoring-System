# Part 05 tests

Static: check the HTML contains no credentials, raw logs, or dynamic endpoints.

Target RHEL:

```bash
sudo apachectl configtest
sudo systemctl is-enabled httpd
sudo systemctl status httpd --no-pager
curl --fail http://localhost/
ls -Z /var/www/html/index.html
```

Test from a permitted private client only after Part 06 review. Target tests: NOT RUN.

