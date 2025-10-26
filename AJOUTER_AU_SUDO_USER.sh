#!/bin/bash

# Script pour ajouter un utilisateur existant au groupe sudo

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo ou en tant que root"
    exit 1
fi

echo "Ajout d'un utilisateur existant au groupe sudo..."

# Lister les utilisateurs existants
echo "Utilisateurs existants :"
cut -d: -f1 /etc/passwd | grep -v "^#" | head -20

# Demander le nom d'utilisateur
read -p "Entrez le nom de l'utilisateur à ajouter au groupe sudo: " username

# Vérifier si l'utilisateur existe
if id "$username" &>/dev/null; then
    # Ajouter au groupe sudo
    usermod -aG sudo $username
    echo "L'utilisateur $username a été ajouté au groupe sudo."
    echo "Groupes de l'utilisateur :"
    groups $username
else
    echo "L'utilisateur $username n'existe pas."
    exit 1
fi