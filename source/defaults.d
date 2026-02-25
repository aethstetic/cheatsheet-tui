module defaults;

import cheatsheet : category, command;

category[] all_categories() {
    return [
        file_ops(),
        permissions(),
        processes(),
        networking(),
        systemd_cmds(),
        package_managers(),
        disk_storage(),
    ];
}

private category file_ops() {
    return category("file ops", "file-ops.txt", [
        command("ls",    "ls [options] [path...]",        "List directory contents",                   "list, directory, files"),
        command("cp",    "cp [options] source dest",       "Copy files and directories",                "copy, duplicate"),
        command("mv",    "mv [options] source dest",       "Move or rename files and directories",      "move, rename"),
        command("rm",    "rm [options] file...",            "Remove files or directories",               "remove, delete"),
        command("mkdir", "mkdir [options] directory...",    "Create directories",                        "make, directory, create"),
        command("rmdir", "rmdir [options] directory...",    "Remove empty directories",                  "remove, directory"),
        command("find",  "find [path] [expression]",       "Search for files in a directory hierarchy", "search, locate"),
        command("ln",    "ln [options] target link_name",  "Create hard and symbolic links",            "link, symlink"),
        command("stat",  "stat [options] file...",          "Display file status and metadata",          "info, metadata, inode"),
        command("touch", "touch [options] file...",         "Create empty file or update timestamps",    "create, timestamp"),
        command("tree",  "tree [options] [directory]",      "List directory contents in tree format",    "directory, recursive, visual"),
        command("file",  "file [options] file...",          "Determine file type",                       "type, identify"),
        command("tar",   "tar [options] [file...]",         "Archive and extract files",                 "archive, compress, extract"),
        command("gzip",  "gzip [options] [file...]",        "Compress or decompress files",              "compress, decompress, gz"),
        command("zip",   "zip [options] archive file...",   "Package and compress files",                "compress, archive"),
        command("unzip", "unzip [options] archive",         "Extract compressed files from ZIP archive", "extract, decompress"),
        command("wc",    "wc [options] [file...]",          "Print line, word, and byte counts",         "count, lines, words"),
        command("head",  "head [options] [file...]",        "Output the first part of files",            "preview, beginning"),
        command("tail",  "tail [options] [file...]",        "Output the last part of files",             "end, follow, log"),
        command("cat",   "cat [options] [file...]",         "Concatenate files and print to stdout",     "print, display, read"),
        command("less",  "less [options] [file...]",        "View file contents with paging",            "pager, view, scroll"),
        command("sort",  "sort [options] [file...]",        "Sort lines of text files",                  "order, arrange"),
        command("uniq",  "uniq [options] [file]",           "Report or omit repeated lines",             "duplicate, unique, filter"),
        command("diff",  "diff [options] file1 file2",      "Compare files line by line",                "compare, difference"),
        command("rsync", "rsync [options] source dest",     "Fast, versatile file copying tool",         "sync, backup, copy, remote"),
    ]);
}

private category permissions() {
    return category("permissions", "permissions.txt", [
        command("chmod",   "chmod [options] mode file...",     "Change file mode bits (permissions)",     "permissions, access, mode"),
        command("chown",   "chown [options] owner[:grp] file", "Change file owner and group",            "owner, group"),
        command("chgrp",   "chgrp [options] group file...",    "Change group ownership",                 "group, ownership"),
        command("umask",   "umask [mode]",                     "Set default file creation permissions",   "default, mask, create"),
        command("sudo",    "sudo [options] command",           "Execute command as another user",         "root, superuser, elevate"),
        command("su",      "su [options] [user]",              "Switch user identity",                   "switch, user, login"),
        command("id",      "id [options] [user]",              "Print user and group IDs",               "user, group, identity"),
        command("groups",  "groups [user]",                    "Print group memberships",                "group, membership"),
        command("passwd",  "passwd [options] [user]",          "Change user password",                   "password, security"),
        command("visudo",  "visudo [options]",                 "Edit sudoers file safely",               "sudoers, admin, config"),
        command("getfacl", "getfacl [options] file...",        "Get file access control lists",          "acl, access, list"),
        command("setfacl", "setfacl [options] file...",        "Set file access control lists",          "acl, access, modify"),
    ]);
}

private category processes() {
    return category("processes", "processes.txt", [
        command("ps",      "ps [options]",                  "Report current process snapshot",          "list, running, status"),
        command("top",     "top [options]",                 "Interactive process viewer",               "monitor, cpu, memory"),
        command("htop",    "htop [options]",                "Enhanced interactive process viewer",      "monitor, interactive"),
        command("kill",    "kill [signal] pid...",           "Send signal to a process",                "signal, terminate, stop"),
        command("killall", "killall [options] name...",      "Kill processes by name",                  "signal, terminate, name"),
        command("pkill",   "pkill [options] pattern",        "Signal processes by name pattern",        "signal, pattern, match"),
        command("pgrep",   "pgrep [options] pattern",        "List processes matching a pattern",       "find, search, match"),
        command("nice",    "nice [options] command",          "Run command with modified scheduling",    "priority, scheduling"),
        command("renice",  "renice [options] pid...",         "Alter priority of running processes",     "priority, adjust"),
        command("nohup",   "nohup command [args]",            "Run command immune to hangups",           "background, persistent"),
        command("jobs",    "jobs [options]",                  "List active jobs in current shell",       "background, status"),
        command("bg",      "bg [job_spec]",                   "Resume suspended job in background",      "background, resume"),
        command("fg",      "fg [job_spec]",                   "Bring background job to foreground",      "foreground, resume"),
        command("wait",    "wait [pid...]",                   "Wait for process to complete",            "synchronize, finish"),
        command("lsof",    "lsof [options]",                  "List open files and processes",           "files, open, network"),
        command("strace",  "strace [options] command",        "Trace system calls and signals",          "debug, trace, syscall"),
        command("time",    "time command [args]",             "Time a command execution",                "benchmark, duration"),
        command("watch",   "watch [options] command",          "Execute command periodically",            "repeat, monitor, interval"),
        command("xargs",   "xargs [options] command",          "Build and execute commands from stdin",   "pipe, arguments, batch"),
    ]);
}

private category networking() {
    return category("network", "networking.txt", [
        command("ip",        "ip [options] object command",     "Show/manipulate routing, devices, tunnels","interface, route, addr"),
        command("ss",        "ss [options]",                    "Socket statistics (replaces netstat)",    "socket, connection, port"),
        command("ping",      "ping [options] destination",      "Send ICMP echo request to host",         "test, connectivity, latency"),
        command("curl",      "curl [options] url",              "Transfer data from/to a server",         "http, download, api, request"),
        command("wget",      "wget [options] url",              "Non-interactive network downloader",      "download, http, ftp"),
        command("dig",       "dig [options] name [type]",       "DNS lookup utility",                     "dns, resolve, query"),
        command("nslookup",  "nslookup [options] host",         "Query DNS name servers",                 "dns, resolve, nameserver"),
        command("host",      "host [options] name",             "DNS lookup utility (simple)",             "dns, resolve"),
        command("netstat",   "netstat [options]",               "Network statistics (legacy, use ss)",     "socket, connection, routing"),
        command("traceroute","traceroute [options] host",       "Trace packet route to host",             "route, hops, path"),
        command("scp",       "scp [options] src dest",          "Secure copy over SSH",                   "copy, remote, ssh, transfer"),
        command("ssh",       "ssh [options] user@host",         "Secure shell remote login",              "remote, login, tunnel"),
        command("rsync",     "rsync [options] src dest",        "Remote file synchronization",            "sync, backup, remote"),
        command("nc",        "nc [options] host port",          "Netcat -- read/write network connections","tcp, udp, listen, connect"),
        command("iptables",  "iptables [options] [chain rule]", "IPv4 packet filter and NAT admin",       "firewall, filter, nat"),
        command("nmap",      "nmap [options] target",           "Network exploration and security scanner","scan, port, discover"),
        command("tcpdump",   "tcpdump [options] [expression]",  "Capture and analyze network packets",    "capture, packet, sniff"),
        command("ifconfig",  "ifconfig [interface] [options]",  "Configure network interfaces (legacy)",  "interface, ip, config"),
    ]);
}

private category systemd_cmds() {
    return category("systemd", "systemd.txt", [
        command("systemctl",      "systemctl [cmd] [unit]",        "Control the systemd system and services","service, start, stop, enable"),
        command("journalctl",     "journalctl [options]",           "Query the systemd journal (logs)",      "log, journal, debug"),
        command("timedatectl",    "timedatectl [command]",          "Control system time and date settings", "time, date, timezone, ntp"),
        command("hostnamectl",    "hostnamectl [command]",          "Control system hostname",               "hostname, name"),
        command("loginctl",       "loginctl [command]",             "Control the systemd login manager",     "session, user, seat"),
        command("localectl",      "localectl [command]",            "Control system locale and keyboard",    "locale, keyboard, language"),
        command("networkctl",     "networkctl [command]",           "Query networkd status",                 "network, interface, status"),
        command("resolvectl",     "resolvectl [command]",           "Resolve domain names, manage DNS",      "dns, resolve, cache"),
        command("coredumpctl",    "coredumpctl [command]",          "Retrieve and process core dumps",       "crash, debug, dump"),
        command("busctl",         "busctl [command]",               "Introspect the D-Bus bus",              "dbus, message, interface"),
        command("systemd-analyze","systemd-analyze [command]",      "Analyze system boot-up performance",    "boot, performance, blame"),
        command("machinectl",     "machinectl [command]",           "Control systemd-nspawn containers",     "container, vm, machine"),
    ]);
}

private category package_managers() {
    return category("packages", "package-managers.txt", [
        command("pacman -S",   "pacman -S package...",           "Install packages (Arch)",              "arch, install"),
        command("pacman -Syu", "pacman -Syu",                    "Full system upgrade (Arch)",           "arch, upgrade, update"),
        command("pacman -Rs",  "pacman -Rs package...",           "Remove package and deps (Arch)",       "arch, remove, uninstall"),
        command("pacman -Ss",  "pacman -Ss query",               "Search remote packages (Arch)",        "arch, search, find"),
        command("pacman -Qs",  "pacman -Qs query",               "Search installed packages (Arch)",     "arch, search, local"),
        command("pacman -Qi",  "pacman -Qi package",             "Package info (Arch)",                  "arch, info, details"),
        command("apt install", "apt install package...",          "Install packages (Debian/Ubuntu)",     "debian, ubuntu, install"),
        command("apt update",  "apt update",                     "Update package index (Debian/Ubuntu)", "debian, ubuntu, refresh"),
        command("apt upgrade", "apt upgrade",                    "Upgrade all packages (Debian/Ubuntu)", "debian, ubuntu, upgrade"),
        command("apt remove",  "apt remove package...",           "Remove packages (Debian/Ubuntu)",      "debian, ubuntu, uninstall"),
        command("apt search",  "apt search query",               "Search packages (Debian/Ubuntu)",      "debian, ubuntu, find"),
        command("dnf install", "dnf install package...",          "Install packages (Fedora/RHEL)",       "fedora, rhel, install"),
        command("dnf update",  "dnf update",                     "Update all packages (Fedora/RHEL)",    "fedora, rhel, upgrade"),
        command("dnf remove",  "dnf remove package...",           "Remove packages (Fedora/RHEL)",        "fedora, rhel, uninstall"),
        command("dnf search",  "dnf search query",               "Search packages (Fedora/RHEL)",        "fedora, rhel, find"),
        command("snap install","snap install package",            "Install a snap package",               "snap, ubuntu, install"),
        command("snap list",   "snap list",                       "List installed snaps",                 "snap, installed"),
        command("flatpak install","flatpak install remote app",   "Install a Flatpak application",        "flatpak, install, app"),
        command("flatpak list","flatpak list",                    "List installed Flatpak apps",          "flatpak, installed"),
    ]);
}

private category disk_storage() {
    return category("disk", "disk-storage.txt", [
        command("df",      "df [options] [file...]",         "Report file system disk space usage",    "space, usage, free"),
        command("du",      "du [options] [file...]",         "Estimate file space usage",              "size, usage, directory"),
        command("mount",   "mount [options] device dir",     "Mount a filesystem",                     "filesystem, attach, device"),
        command("umount",  "umount [options] dir|device",    "Unmount a filesystem",                   "filesystem, detach, eject"),
        command("fdisk",   "fdisk [options] device",         "Manipulate disk partition table",        "partition, table, mbr"),
        command("lsblk",   "lsblk [options]",               "List block devices",                     "device, partition, disk"),
        command("blkid",   "blkid [options] [device...]",    "Locate/print block device attributes",   "uuid, label, filesystem"),
        command("mkfs",    "mkfs [options] device",          "Build a filesystem on a device",         "format, filesystem, create"),
        command("fsck",    "fsck [options] device",          "Check and repair a filesystem",          "repair, check, integrity"),
        command("dd",      "dd [operand...]",                "Convert and copy a file (low-level)",    "copy, image, raw, block"),
        command("parted",  "parted [options] device",        "Partition manipulation program",         "partition, resize, gpt"),
        command("lvm",     "lvm [command]",                  "LVM2 logical volume manager tools",      "logical, volume, lvm"),
        command("mkswap",  "mkswap [options] device",        "Set up a swap area",                     "swap, memory, virtual"),
        command("swapon",  "swapon [options] device",        "Enable swap area",                       "swap, enable, memory"),
        command("swapoff", "swapoff [options] device",       "Disable swap area",                      "swap, disable, memory"),
        command("tune2fs", "tune2fs [options] device",       "Adjust ext2/3/4 filesystem parameters",  "ext4, tune, filesystem"),
        command("smartctl","smartctl [options] device",       "Control SMART disk monitoring",          "health, smart, monitor"),
    ]);
}
