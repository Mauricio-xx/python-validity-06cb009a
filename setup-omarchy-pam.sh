#!/bin/bash
# Point sudo, polkit, and the Omarchy lock screen at the enrolled fingerprint.
# Same stack as `omarchy setup security fingerprint`, without reinstalling
# stock fprintd (that package conflicts with this driver).
set -euo pipefail

gate_bin=/usr/bin/omarchy-hw-laptop-closed
if [[ ! -x $gate_bin ]]; then
    echo "This script is for Omarchy. $gate_bin is not on this system." >&2
    exit 1
fi

if ! fprintd-list "${USER}" 2>/dev/null | grep -qi finger; then
    echo "Enroll a finger first: fprintd-enroll" >&2
    exit 1
fi

gate="auth      [success=1 default=ignore] pam_exec.so quiet ${gate_bin}"

if ! grep -q pam_fprintd.so /etc/pam.d/sudo; then
    sudo sed -i '1i auth      sufficient pam_fprintd.so' /etc/pam.d/sudo
fi
if ! grep -q 'omarchy-hw-laptop-closed' /etc/pam.d/sudo; then
    sudo sed -i "/pam_fprintd\\.so/i ${gate}" /etc/pam.d/sudo
fi

if [[ ! -f /etc/pam.d/polkit-1 ]]; then
    sudo tee /etc/pam.d/polkit-1 >/dev/null << EOF
${gate}
auth      sufficient pam_fprintd.so
auth      required pam_unix.so

account   required pam_unix.so
password  required pam_unix.so
session   required pam_unix.so
EOF
fi

sudo tee /etc/pam.d/omarchy-lock-fingerprint >/dev/null << 'EOF'
#%PAM-1.0
auth       required                    pam_fprintd.so
account    include                     system-local-login
EOF

echo "Fingerprint PAM is in place for sudo, polkit, and the lock screen."
echo "The password remains the fallback when the lid is closed or the finger does not match."
