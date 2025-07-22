#!/bin/bash

# Exercise Videos Setup Script for FitConnect
# This script helps you configure the ExerciseDB API for exercise video demonstrations

echo "🏋️  FitConnect Exercise Videos Setup"
echo "======================================"
echo ""

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if APIConfiguration.swift exists
API_CONFIG_FILE="./Helpers/APIConfiguration.swift"

if [ ! -f "$API_CONFIG_FILE" ]; then
    echo -e "${RED}❌ APIConfiguration.swift not found!${NC}"
    echo "Make sure you're running this script from the FitConnect project root."
    exit 1
fi

echo "✅ Found APIConfiguration.swift"
echo ""

# Check current API key status
CURRENT_KEY=$(grep -o '"[^"]*"' "$API_CONFIG_FILE" | grep -v "YOUR_RAPIDAPI_KEY_HERE" | head -n 1 | tr -d '"')

if [[ "$CURRENT_KEY" != "" && "$CURRENT_KEY" != "YOUR_RAPIDAPI_KEY_HERE" ]]; then
    echo -e "${GREEN}✅ API key already configured!${NC}"
    echo "Current key: ${CURRENT_KEY:0:8}..."
    echo ""
    read -p "Do you want to update it? (y/N): " UPDATE_KEY
    if [[ $UPDATE_KEY != [Yy] ]]; then
        echo "Setup cancelled. Your existing configuration is unchanged."
        exit 0
    fi
fi

echo -e "${BLUE}📋 To get your free API key:${NC}"
echo "1. Go to: https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb"
echo "2. Sign up for a free RapidAPI account"
echo "3. Subscribe to the ExerciseDB API (free tier available)"
echo "4. Copy your API key from the dashboard"
echo ""

read -p "Enter your RapidAPI key: " NEW_API_KEY

# Validate API key format (basic check)
if [[ ${#NEW_API_KEY} -lt 20 ]]; then
    echo -e "${RED}❌ API key seems too short. Please check and try again.${NC}"
    exit 1
fi

if [[ $NEW_API_KEY == *" "* ]]; then
    echo -e "${RED}❌ API key should not contain spaces. Please check and try again.${NC}"
    exit 1
fi

# Create backup
cp "$API_CONFIG_FILE" "$API_CONFIG_FILE.backup"
echo "✅ Created backup: APIConfiguration.swift.backup"

# Update the API key
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/YOUR_RAPIDAPI_KEY_HERE/$NEW_API_KEY/g" "$API_CONFIG_FILE"
else
    # Linux
    sed -i "s/YOUR_RAPIDAPI_KEY_HERE/$NEW_API_KEY/g" "$API_CONFIG_FILE"
fi

echo ""
echo -e "${GREEN}🎉 Success! API key configured.${NC}"
echo ""

# Test the configuration
echo "🧪 Testing API configuration..."

# Check if the replacement worked
if grep -q "$NEW_API_KEY" "$API_CONFIG_FILE"; then
    echo -e "${GREEN}✅ API key successfully updated in configuration file${NC}"
else
    echo -e "${RED}❌ Failed to update API key. Please check the file manually.${NC}"
    # Restore backup
    mv "$API_CONFIG_FILE.backup" "$API_CONFIG_FILE"
    echo "Restored original configuration from backup."
    exit 1
fi

echo ""
echo -e "${GREEN}🏆 Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Build and run your app in Xcode"
echo "2. Navigate to Workouts → Dance → Tap any exercise info (ⓘ)"
echo "3. You should see exercise demonstration videos!"
echo ""
echo -e "${YELLOW}💡 Tip: Check Xcode console for helpful debug messages${NC}"
echo ""
echo "Need help? Check EXERCISE_VIDEOS_SETUP.md for detailed instructions."

# Clean up backup if successful
rm -f "$API_CONFIG_FILE.backup"