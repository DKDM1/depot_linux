#!/bin/bash

# Script pour créer un nouvel utilisateur avec privileges sudo

# Vérifier que le script est exécuté en root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo ou en tant que root"
    exit 1
fi

echo "Création d'un nouvel utilisateur sudo..."

# Demander le nom d'utilisateur
read -p "Entrez le nom du nouvel utilisateur: " username

# Vérifier si l'utilisateur existe déjà
if id "$username" &>/dev/null; then
    echo "L'utilisateur $username existe déjà."
    exit 1
fi

# Créer l'utilisateur
adduser --gecos "" $username

# Ajouter l'utilisateur au groupe sudo
usermod -aG sudo $username

# Vérification
echo "Utilisateur $username créé avec succès et ajouté au groupe sudo."
groups $username