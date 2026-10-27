# Network plan

## Proposed isolated lab values

| Device | Hostname | Example address |
|---|---|---|
| Main server | `rhel-srv01` | `192.168.56.10/24` |
| Optional client | `rhel-cli01` | `192.168.56.20/24` |
| Private subnet | - | `192.168.56.0/24` |

These are documentation defaults only. VMware host-only networks vary. Before configuring anything, inspect `ip -br address`, `ip route`, and `nmcli connection show`; confirm the VM network is private and the proposed addresses are unused. Update `MASTER_SPEC.md` before adopting different canonical values.

## Allowed service intent

| Service | Port | Scope |
|---|---:|---|
| SSH | TCP/22 | Trusted administrator source(s) only |
| HTTP | TCP/80 | Private lab subnet only |
| NFSv4 | TCP/2049 | Private lab subnet only, only when enabled |

Do not open broad port ranges or expose the VM publicly. The actual firewalld zone and interface must be discovered on-host before applying rules. Preserve console access and have rollback ready.

## Hostname and name resolution

Use `rhel-srv01` and optional `rhel-cli01`. `/etc/hosts` entries are acceptable for an isolated lab and must be documented. Do not hard-code an assumed interface name, gateway, DNS server, or subnet into automation.

