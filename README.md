# Backup-Configuration-IPBX-XORCOM
# Description: Scripts Bash pour automatiser les sauvegardes de systèmes **Xorcom IPBX** via NFS sur NAS Synology

## 📁 Structure du dépôt proposée
```
nas-backup-scripts/
├── debian_8.sh               # Pour Debian 8.8 ou antérieur
├── debian_11_tar.sh          # Pour Debian 11+ (archive .tar)
├── debian_11_zip.sh          # Pour Debian 11+ (archive .zip)
├── centos.sh                 # Pour CentOS 7 et 8+
├── debian_jessie_general.sh  # Version générique pour Jessie
├── .gitignore
├── README.md
└── LICENSE (MIT)
```

## 📄 README.md (extrait)
```md
# NAS Backup Scripts – Xorcom IPBX

Ce dépôt regroupe plusieurs scripts d’installation et de sauvegarde compatibles avec différents environnements Linux (Debian 8+, Debian 11, CentOS) pour automatiser la sauvegarde d’équipements **Xorcom IPBX** vers des **NAS Synology** via **NFS**.

### Versions disponibles
- `debian_8.sh` – Support Debian 8.8 ou plus ancien
- `debian_11_tar.sh` – Support Debian 11+ avec archives `.tar`
- `debian_11_zip.sh` – Support Debian 11+ avec archives `.zip`
- `centos.sh` – Support CentOS 7 et 8+
- `debian_jessie_general.sh` – Version de secours générique basée sur Jessie

### Utilisation
```bash
chmod +x debian_11_tar.sh
sudo ./debian_11_tar.sh
```

### Tâche CRON installée automatiquement :
```
0 2 * * 1 root /root/backup_nfs
```

### Auteur
Sacha Veyon Rodriguez – Stage SBS79 – 2025
```

## 📄 .gitignore
```
*.tar
*.zip
*.log
/tmp/*
/mnt/*
```

## 📝 Licence
MIT – Libre d'utilisation et de modification.

---
Souhaites-tu que je te génère un `.zip` complet avec tous les fichiers prêts à publier sur GitHub ?

