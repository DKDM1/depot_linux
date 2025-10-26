#!/bin/bash

# Script pour vérifier et gérer les utilisateurs sudo

echo "=== GESTION DES UTILISATEURS SUDO ==="

# Lister tous les utilisateurs avec des privileges sudo
echo ""
echo "1. Utilisateurs avec accès sudo :"
getent group sudo | cut -d: -f4 | tr ',' '\n'

# Vérifier un utilisateur spécifique
echo ""
read -p "Vérifier un utilisateur spécifique (laisser vide pour ignorer): " check_user

if [ -n "$check_user" ]; then
    if id "$check_user" &>/dev/null; then
        echo "Statut de $check_user :"
        groups "$check_user" | grep -q sudo && echo "✅ A accès sudo" || echo "❌ N'a pas accès sudo"
        
        # Tester les privileges sudo
        echo "Test des privileges sudo :"
        sudo -u "$check_user" sudo -n true 2>/dev/null && echo "✅ Privileges sudo actifs" || echo "❌ Privileges sudo inactifs"
    else
        echo "L'utilisateur $check_user n'existe pas."
    fi
fi

# Retirer les privileges sudo
echo ""
read -p "Retirer un utilisateur du groupe sudo (laisser vide pour ignorer): " remove_user

if [ -n "$remove_user" ]; then
    if id "$remove_user" &>/dev/null; then
        # Vérifier qu'on ne retire pas le dernier utilisateur sudo
        sudo_count=$(getent group sudo | cut -d: -f4 | tr ',' '\n' | wc -l)
        if [ "$sudo_count" -le 1 ]; then
            echo "⚠️  Attention: Vous allez retirer le dernier utilisateur sudo!"
            read -p "Êtes-vous sûr? (o/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Oo]$ ]]; then
                echo "Opération annulée."
                exit 0
            fi
        fi
        
        # Retirer du groupe sudo
        gpasswd -d "$remove_user" sudo
        echo "✅ Utilisateur $remove_user retiré du groupe sudo"
    else
        echo "L'utilisateur $remove_user n'existe pas."
    fi
fi