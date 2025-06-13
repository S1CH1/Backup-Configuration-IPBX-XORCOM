#!/bin/bash
set -e

# sv4.sh - Version propre pour Debian 11 (Bullseye) sans paquets obsolètes

#  1. Vérification des droits root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ce script doit être lancé en tant que root." >&2
  exit 1
fi

# 2. Affichage de l'architecture
ARCH=$(dpkg --print-architecture)
echo "[*] Détection de l'architecture : $ARCH"

# 3. Nettoyage des anciens dépôts
echo "[*] Nettoyage des anciens dépôts..."
rm -f /etc/apt/sources.list.d/*
sed -i '/jessie/d' /etc/apt/sources.list || true
rm -f /etc/apt/apt.conf.d/10no-check-valid /etc/apt/apt.conf.d/99insecure || true

# 4. Configuration propre des dépôts Debian 11 (Bullseye)
echo "[*] Configuration des dépôts officiels Bullseye..."
cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian-security bullseye-security main
deb http://deb.debian.org/debian bullseye-updates main
EOF

# 5. Mise à jour et installation des paquets NFS utiles
apt update
echo "[*] Installation des paquets NFS..."
apt install -y nfs-common rpcbind

# 6. Demande du nom du client
read -rp "Entrez le nom du client : " CLIENT
MOUNTPOINT="82.127.105.24:/volume1/Ipconnect/$CLIENT"
TMPDIR="/mnt/testnfs_$CLIENT"

mkdir -p "$TMPDIR"

echo "[*] Test du montage NFS sur $MOUNTPOINT..."
if mount -t nfs -o vers=3 "$MOUNTPOINT" "$TMPDIR"; then
  echo "[✔] Montage NFS réussi."
  umount "$TMPDIR"
else
  echo "❌ Échec du montage NFS. Le dossier '$CLIENT' n'existe pas ou n'est pas autorisé en NFS." >&2
  rm -rf "$TMPDIR"
  exit 1
fi

# 7. Création du script de sauvegarde
BACKUP_SCRIPT="/root/backup_nfs"
echo "[*] Création du script de sauvegarde à $BACKUP_SCRIPT"

cat <<EOF > "$BACKUP_SCRIPT"
#!/bin/bash
set -e

CLIENT="$CLIENT"
NAS_PATH="82.127.105.24:/volume1/Ipconnect/\$CLIENT"
TMP_LOCAL=\$(mktemp -d)
TMP_NFS="/mnt/nfs_\$CLIENT"

echo "[*] Création des dossiers..."
mkdir -p "\$TMP_NFS"

echo "[*] Montage NFS..."
if mount -t nfs -o vers=3 "\$NAS_PATH" "\$TMP_NFS"; then
  echo "[*] Lancement de la sauvegarde locale..."
  /usr/share/ombutel/scripts/backup -d "\$TMP_LOCAL"

  echo "[*] Recherche de l'archive générée..."
  ARCHIVE=\$(find "\$TMP_LOCAL" -type f -name "cpbx-*.zip" | head -n 1)

  if [ -z "\$ARCHIVE" ]; then
    echo "❌ Aucun fichier .tar trouvé dans \$TMP_LOCAL"
    ls -lR "\$TMP_LOCAL"
    umount "\$TMP_NFS"
    rm -rf "\$TMP_LOCAL"
    exit 1
  fi

  echo "[*] Copie vers le NAS..."
  cp "\$ARCHIVE" "\$TMP_NFS/"

  echo "[*] Nettoyage..."
  umount "\$TMP_NFS"
  rm -rf "\$TMP_LOCAL"

  echo "[✅] Sauvegarde transférée avec succès dans \$NAS_PATH"
else
  echo "❌ Erreur de montage NFS" >&2
  exit 1
fi
EOF

chmod +x "$BACKUP_SCRIPT"

# 8. Ajout au cron si absent
CRON_FILE="/etc/cron.d/backup_nfs"
echo "[*] Vérification de la tâche CRON..."
if ! grep -q "$BACKUP_SCRIPT" "$CRON_FILE" 2>/dev/null; then
  echo "0 2 * * 1 root $BACKUP_SCRIPT" >> "$CRON_FILE"
  echo "[+] Tâche CRON ajoutée."
else
  echo "[✔] Tâche CRON déjà présente."
fi

echo "[✅] Configuration terminée avec succès."
exit 0
