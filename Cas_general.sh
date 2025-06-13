#!/bin/bash
set -e

# ========================================
# Script : sv3.sh
# Objectif : Préparer une machine Debian Jessie pour effectuer des sauvegardes via NFS
# Généralement ce script est utilisé avec des anciennes version de Debian car il utilise des paquets Jessie, qui sont maintenant archivé
# ========================================

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être lancé en tant que root." >&2
  exit 1
fi

# Détection de l'architecture
ARCH=$(dpkg --print-architecture)
echo "[*] Détection de l'architecture : $ARCH"

# Configuration des dépôts Debian archivés (Jessie)
echo "[*] Configuration des dépôts Debian archivés..."
cat > /etc/apt/sources.list <<EOF
deb http://archive.debian.org/debian jessie main
deb http://archive.debian.org/debian-security jessie/updates main
EOF
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/10no-check-valid

# Mise à jour et installation des paquets nécessaires
echo "[*] Mise à jour des paquets et installation NFS"
apt update
apt install -y --allow-unauthenticated nfs-common rpcbind keyutils libnfsidmap2

# Demande du nom du client
read -rp "Entrez le nom du client : " CLIENT
MOUNTPOINT="82.127.105.24:/volume1/Ipconnect/$CLIENT"
TMPDIR="/mnt/testnfs_$CLIENT"

mkdir -p "$TMPDIR"

# Test du montage NFS
echo "[*] Test du montage NFS sur $MOUNTPOINT..."
if mount -t nfs -o vers=3 "$MOUNTPOINT" "$TMPDIR"; then
  echo "[*] Montage NFS réussi."
  umount "$TMPDIR"
else
  echo "Échec du montage NFS. Le dossier '$CLIENT' n'existe pas ou n'est pas autorisé en NFS." >&2
  rm -rf "$TMPDIR"
  exit 1
fi

# Création du script de sauvegarde
BACKUP_SCRIPT="/root/backup_nfs"
echo "[*] Création du script de sauvegarde à $BACKUP_SCRIPT"

cat <<EOF > "$BACKUP_SCRIPT"
#!/bin/bash
set -e

TEMPDIR=\$(mktemp -d)
MOUNTPOINT="82.127.105.24:/volume1/Ipconnect/$CLIENT"

echo "[*] Montage de \$MOUNTPOINT..."
if mount -t nfs -o vers=3 "\$MOUNTPOINT" "\$TEMPDIR"; then
  echo "[*] Sauvegarde..."
  /usr/share/ombutel/scripts/backup -d "\$TEMPDIR"
  umount "\$TEMPDIR"
  rm -rf "\$TEMPDIR"
else
  echo "Échec du montage pour \$MOUNTPOINT"
  exit 1
fi
EOF

chmod +x "$BACKUP_SCRIPT"

# Ajout au CRON si absent
CRON_FILE="/etc/cron.d/backup_nfs"
echo "[*] Vérification de la tâche CRON..."
if ! grep -q "$BACKUP_SCRIPT" "$CRON_FILE" 2>/dev/null; then
  echo "0 2 * * 1 root $BACKUP_SCRIPT" >> "$CRON_FILE"
  echo "[*] Tâche CRON ajoutée."
else
  echo "[*] Tâche CRON déjà présente."
fi

echo "[*] Configuration terminée avec succès."
exit 0
