#!/bin/bash

# Skapar användare, sätter upp hemkataloger och en personlig welcome.txt.

# Måste köras som root, annars funkar inte useradd
if [ "$(id -u)" -ne 0 ]; then
    echo "Fel: scriptet måste köras som root." >&2
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Användning: $0 <användare1> <användare2> ..." >&2
    exit 1
fi

# Första omgången: skapa användarna och deras mappar
for username in "$@"; do
    echo "Bearbetar $username..."

    if id "$username" >/dev/null 2>&1; then
        echo "Användaren $username finns redan, hoppar över."
    else
        useradd -m -s /bin/bash "$username"
        if [ $? -ne 0 ]; then
            echo "Kunde inte skapa $username." >&2
            continue
        fi
    fi

    home_dir="/home/$username"

    for dir in Documents Downloads Work; do
        mkdir -p "$home_dir/$dir"
        chown "$username":"$username" "$home_dir/$dir"
        chmod 700 "$home_dir/$dir"
    done
done

# Andra omgången: skriv welcome.txt först nu, så att varje fil innehåller
# alla andra användare (även de som precis skapats)
for username in "$@"; do
    if ! id "$username" >/dev/null 2>&1; then
        continue
    fi

    welcome_file="/home/$username/welcome.txt"

    echo "Välkommen $username" > "$welcome_file"
    echo "" >> "$welcome_file"
    echo "Andra användare i systemet:" >> "$welcome_file"

    # Lista alla användare i /etc/passwd förutom den aktuella
    while IFS=: read -r user _; do
        if [ "$user" != "$username" ]; then
            echo "$user" >> "$welcome_file"
        fi
    done < /etc/passwd

    chown "$username":"$username" "$welcome_file"
    chmod 600 "$welcome_file"
done

echo "Klart!"
exit 0