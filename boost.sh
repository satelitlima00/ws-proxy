#!/usr/bin/env bash
set -e

echo "=== WebSocket/TCP Proxy VPS Optimizer ==="

# --------------------------------------------------
# 1. File descriptor limits
# --------------------------------------------------

cat >/etc/security/limits.d/websocket-tcp.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

# systemd global defaults
mkdir -p /etc/systemd/system.conf.d

cat >/etc/systemd/system.conf.d/99-websocket-tcp.conf <<'EOF'
[Manager]
DefaultLimitNOFILE=1048576
EOF

mkdir -p /etc/systemd/user.conf.d

cat >/etc/systemd/user.conf.d/99-websocket-tcp.conf <<'EOF'
[Manager]
DefaultLimitNOFILE=1048576
EOF


# --------------------------------------------------
# 2. Kernel network tuning
# --------------------------------------------------

cat >/etc/sysctl.d/99-websocket-tcp.conf <<'EOF'

# ==============================
# File handles
# ==============================

fs.file-max = 2097152


# ==============================
# Listen / SYN backlog
# ==============================

net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 262144


# ==============================
# TCP connection handling
# ==============================

net.ipv4.tcp_fin_timeout = 15

net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 4

net.ipv4.tcp_syncookies = 1


# ==============================
# TIME_WAIT
# ==============================

net.ipv4.tcp_tw_reuse = 1


# ==============================
# TCP orphan sockets
# ==============================

net.ipv4.tcp_max_orphans = 262144


# ==============================
# TIME_WAIT buckets
# ==============================

net.ipv4.tcp_max_tw_buckets = 2000000


# ==============================
# TCP memory
# ==============================

net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432


# ==============================
# Network buffers
# ==============================

net.core.rmem_max = 33554432
net.core.wmem_max = 33554432

net.core.rmem_default = 262144
net.core.wmem_default = 262144


# ==============================
# TCP window scaling
# ==============================

net.ipv4.tcp_window_scaling = 1


# ==============================
# Fast open
# ==============================

net.ipv4.tcp_fastopen = 3

EOF

sysctl --system


# --------------------------------------------------
# 3. systemd reload
# --------------------------------------------------

systemctl daemon-reexec


echo
echo "=========================================="
echo " Current limits"
echo "=========================================="

ulimit -n || true

echo
echo "fs.file-max:"
cat /proc/sys/fs/file-max

echo
echo "somaxconn:"
cat /proc/sys/net/core/somaxconn

echo
echo "tcp_max_syn_backlog:"
cat /proc/sys/net/ipv4/tcp_max_syn_backlog

echo
echo "tcp_max_tw_buckets:"
cat /proc/sys/net/ipv4/tcp_max_tw_buckets

echo
echo "tcp_max_orphans:"
cat /proc/sys/net/ipv4/tcp_max_orphans

echo
echo "=========================================="
echo " DONE"
echo "=========================================="
echo
echo "IMPORTANT:"
echo "Reboot VPS after this:"
echo "  reboot"
