#!/bin/bash

URL="http://localhost:8000/test"  # Replace with the URL you want to test
TOTAL_REQUESTS=1000
TOTAL_TIME=0

echo "Testing $URL..."

for i in $(seq 1 $TOTAL_REQUESTS); do
    # Time the request and calculate the difference in milliseconds
    START=$(date +%s%3N)
    RESPONSE=$(curl -s -w "%{time_total}" -o /dev/null $URL)
    END=$(date +%s%3N)

    # Calculate request time (milliseconds)
    TIME=$((END - START))
    TOTAL_TIME=$((TOTAL_TIME + TIME))

    echo "Request $i: Time: $TIME ms"
done

# Calculate average time
AVERAGE_TIME=$((TOTAL_TIME / TOTAL_REQUESTS))
echo "Average time over $TOTAL_REQUESTS requests: $AVERAGE_TIME ms"
