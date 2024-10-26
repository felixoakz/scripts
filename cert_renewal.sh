#!/bin/bash

# Get the expiration date in seconds since epoch
expiry_date=$(sudo openssl x509 -in /etc/letsencrypt/live/oakz.duckdns.org/fullchain.pem -noout -enddate | cut -d'=' -f2)
expiry_seconds=$(date -d "$expiry_date" +%s)

# Get the current date in seconds since epoch
current_seconds=$(date +%s)

# Calculate the difference in days
let days_left=($expiry_seconds-$current_seconds)/86400

# Check if the certificate expires within the next 30 days
if [ $days_left -le 30 ]; then
    echo "Certificate expires in $days_left days. Attempting to renew it..."

    # Attempt to renew the certificate
    sudo certbot renew --quiet

    # Check if renewal was successful
    if [ $? -eq 0 ]; then
        echo "Certificate renewed successfully."
    else
        echo "Failed to renew the certificate. Please check the logs for details."
    fi
else
    echo "Certificate is valid for $days_left more days."
fi
