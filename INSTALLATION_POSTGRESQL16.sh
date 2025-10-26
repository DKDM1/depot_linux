#!/bin/bash

# Script d'installation de PostgreSQL 16 avec configuration d'accès distant
# Testé sur Ubuntu 20.04/22.04

set -e  # Arrêter le script en cas d'erreur

echo "=========================================="
echo " Installation de PostgreSQL 16"
echo "=========================================="

# Vérifier si le script est exécuté en root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec les privilèges sudo"
    exit 1
fi

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages d'information
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Mise à jour du système
info "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances
info "Installation des dépendances..."
apt install wget ca-certificates gnupg -y

# Ajout du dépôt PostgreSQL
info "Ajout du dépôt PostgreSQL officiel..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Téléchargement et ajout de la clé GPG
info "Ajout de la clé GPG du dépôt PostgreSQL..."
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Mise à jour des paquets
info "Mise à jour de la liste des paquets..."
apt update

# Installation de PostgreSQL 16
info "Installation de PostgreSQL 16..."
apt install postgresql-16 postgresql-client-16 -y

# Vérification du service
info "Vérification du statut du service PostgreSQL..."
systemctl status postgresql --no-pager

# Affichage de la version
info "Version de PostgreSQL installée :"
psql --version

echo ""
info "Configuration de l'accès distant..."

# Configuration de postgresql.conf
POSTGRESQL_CONF="/etc/postgresql/16/main/postgresql.conf"
if [ -f "$POSTGRESQL_CONF" ]; then
    info "Configuration de listen_addresses dans postgresql.conf..."
    # Sauvegarde de la configuration originale
    cp "$POSTGRESQL_CONF" "${POSTGRESQL_CONF}.backup"
    
    # Modification de listen_addresses
    sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF"
    sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF"
    
    info "listen_addresses configuré sur '*'"
else
    error "Fichier $POSTGRESQL_CONF non trouvé"
    exit 1
fi

# Configuration de pg_hba.conf
PG_HBA_CONF="/etc/postgresql/16/main/pg_hba.conf"
if [ -f "$PG_HBA_CONF" ]; then
    info "Configuration de l'authentification dans pg_hba.conf..."
    # Sauvegarde de la configuration originale
    cp "$PG_HBA_CONF" "${PG_HBA_CONF}.backup"
    
    # Ajout de la règle pour l'accès distant
    echo "host    all             all             0.0.0.0/0               md5" >> "$PG_HBA_CONF"
    
    info "Règle d'accès distant ajoutée à pg_hba.conf"
else
    error "Fichier $PG_HBA_CONF non trouvé"
    exit 1
fi

# Redémarrage du service PostgreSQL
info "Redémarrage du service PostgreSQL..."
systemctl restart postgresql

# Configuration du firewall
info "Configuration du firewall UFW..."
ufw --force enable
ufw allow ssh
ufw allow 5432/tcp
info "Port 5432 ouvert dans le firewall"

# Instructions pour finaliser la configuration
echo ""
echo "=========================================="
echo " Installation terminée avec succès!"
echo "=========================================="
info "PostgreSQL 16 est maintenant installé et configuré"
echo ""
warn "Étapes manuelles requises :"
echo "1. Définir un mot de passe pour l'utilisateur postgres :"
echo "   sudo -u postgres psql -c \"ALTER USER postgres PASSWORD 'votre_mot_de_passe';\""
echo ""
echo "2. Pour vous connecter à distance, utilisez :"
echo "   psql -h IP_SERVEUR -U postgres -d postgres"
echo ""
echo "3. Vérifier la configuration réseau :"
echo "   sudo ss -tlnp | grep 5432"
echo ""
info "Les fichiers de configuration ont été sauvegardés avec l'extension .backup"

# Vérification finale
echo ""
info "Vérification finale..."
systemctl is-active postgresql > /dev/null && info "PostgreSQL est en cours d'exécution" || error "PostgreSQL n'est pas démarré"

echo ""
info "Script d'installation terminé!"