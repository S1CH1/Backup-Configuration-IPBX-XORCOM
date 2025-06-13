#!/bin/bash

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
  echo "Erreur: Ce script doit être lancé en tant que root." >&2
  exit 1
fi

ARCH=$(dpkg --print-architecture)
echo "[*] Détection de l'architecture : $ARCH"
BASE_URL="http://support.ipconnect.fr/Prive"

install_from_repo() {
  echo "[*] Installation via les dépôts APT"
  apt update && apt install -y nfs-common rpcbind keyutils libnfsidmap2
}

case "$ARCH" in
  arm64)
    echo "[*] Téléchargement des paquets arm64..."
    cd /tmp || exit 1
    wget -q "$BASE_URL/nfs_swift.tar.gz" -O nfs_swift.tar.gz
    if [ $? -ne 0 ]; then
      echo "Erreur: Téléchargement échoué." >&2
      install_from_repo
    else
      tar -xvzf nfs_swift.tar.gz && rm nfs_swift.tar.gz
      dpkg -i *.deb || install_from_repo
    fi
    ;;
  armhf|armel)
    echo "[*] Téléchargement des paquets armhf..."
    cd /tmp || exit 1
    wget -q "$BASE_URL/nfs_swift_armhf.tar.gz" -O nfs_swift_armhf.tar.gz
    if [ $? -ne 0 ]; then
      echo "Erreur: Téléchargement échoué." >&2
      install_from_repo
    else
      tar -xvzf nfs_swift_armhf.tar.gz && rm nfs_swift_armhf.tar.gz
      dpkg -i *.deb || install_from_repo
    fi
    ;;
  amd64)
    echo "[*] Système x86_64 détecté. Installation via apt."
    install_from_repo
    ;;
  *)
    echo "Architecture inconnue ($ARCH), installation via apt par défaut."
    install_from_repo
    ;;
esac

read -rp "Entrez le nom du client : " CLIENT
BACKUP_SCRIPT_PATH="/root/backup_nfs"
echo "[*] Création du script de sauvegarde à $BACKUP_SCRIPT_PATH"

cat <<EOF > "$BACKUP_SCRIPT_PATH"
#!/bin/bash
set -e

TEMPDIR=\$(mktemp -d)
MOUNTPOINT="82.127.105.24:/volume1/Ipconnect/$CLIENT"

echo "[*] Tentative de montage NFS..."
if mount -t nfs -o rw,relatime,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys \$MOUNTPOINT \$TEMPDIR; then
  echo "[*] Montage réussi."
else
  echo "Erreur : Le dossier /volume1/Ipconnect/$CLIENT n'existe pas ou n'est pas partagé en NFS." >&2
  rm -rf \$TEMPDIR
  exit 1
fi

echo "[*] Sauvegarde en cours..."
/usr/share/ombutel/scripts/backup -d \$TEMPDIR

echo "[*] Démontage..."
umount \$TEMPDIR
rm -rf \$TEMPDIR
EOF

chmod +x "$BACKUP_SCRIPT_PATH"

echo "[*] Lancement du test de sauvegarde..."
"$BACKUP_SCRIPT_PATH"

CRON_FILE="/etc/cron.d/backup_nfs"
echo "[*] Configuration du cron à $CRON_FILE"
if grep -q "$BACKUP_SCRIPT_PATH" "$CRON_FILE" 2>/dev/null; then
  echo "[*] La tâche cron existe déjà."
else
  echo "0 2 * * 1 root $BACKUP_SCRIPT_PATH" > "$CRON_FILE"
fi

echo "[*] Configuration terminée avec succès."
exit 0
