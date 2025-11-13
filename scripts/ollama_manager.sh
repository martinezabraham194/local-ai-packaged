#!/bin/bash

# A simple shell script to manage loading and unloading Ollama models.

# --- Define some colors for readability ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Function 1: Load Models ---
# This function loads a model in the background and sets it to 'keep_alive'
_load_model_task() {
    local model_name=$1
    echo -e "[${YELLOW}Loading $model_name${NC}] Sending request to load and keep alive..."

    # We use 'curl' to send a request to the API.
    # - "prompt": " " -> We send a blank prompt so the command returns immediately.
    # - "keep_alive": -1 -> This tells the Ollama server to keep the model in
    #                       memory indefinitely (until stopped or server restarts).
    # We send all output to /dev/null to keep the terminal clean.
    curl -s http://localhost:11434/api/generate -d '{
      "model": "'"$model_name"'",
      "prompt": " ", 
      "keep_alive": -1
    }' > /dev/null

    echo -e "[${GREEN}Success${NC}] Load request for '$model_name' is complete."
}

load_models() {
    echo -e "\n${BLUE}--- Load Models (up to 2) ---${NC}"
    echo -n "Enter model names (space-delimited): "
    read model_list

    if [ -z "$model_list" ]; then
        echo "No models entered. Returning to menu."
        return
    fi

    # Read the space-delimited string into an array
    read -a models_array <<< "$model_list"

    count=0
    for model in "${models_array[@]}"; do
        if [ $count -ge 2 ]; then
            echo -e "${YELLOW}Warning: Loading first 2 models only.${NC}"
            break
        fi
        
        # Run the load task in the background (&)
        # This lets the script load models in parallel
        # and returns you to the menu immediately.
        _load_model_task "$model" &
        
        count=$((count + 1))
    done

    echo -e "\n${GREEN}Load commands sent. Models are loading in the background.${NC}"
    echo "Use 'View running models' (option 3) to check their status."
}

# --- Function 2: Unload Model ---
unload_model() {
    echo -e "\n${BLUE}--- Unload a Model ---${NC}"
    echo -n "Enter model name to unload (e.g., 'llama3:latest'): "
    read model_name

    if [ -z "$model_name" ]; then
        echo "No model entered. Returning to menu."
        return
    fi

    echo -e "Attempting to unload '${YELLOW}$model_name${NC}'..."
    
    # Use the official 'ollama stop' command
    ollama stop "$model_name"
    
    echo -e "${GREEN}Unload command sent.${NC}"
}

# --- Function 3: View Models ---
view_models() {
    echo -e "\n${BLUE}--- Currently Running Models (from 'ollama ps') ---${NC}"
    
    # Capture the output of 'ollama ps'
    output=$(ollama ps)
    
    # Check if the output has more than 1 line (the header line)
    if [ $(echo "$output" | wc -l) -le 1 ]; then
        echo "No models are currently running."
    else
        # Print the output from 'ollama ps'
        echo "$output"
    fi
}

# --- Initial Server Check ---
echo "Checking Ollama server connection..."
if ! curl -s http://localhost:11434/ > /dev/null; then
    echo -e "${YELLOW}Error: Could not connect to Ollama server at http://localhost:11434.${NC}"
    echo "Please ensure the Ollama service is running."
    echo "You can try: ${GREEN}sudo systemctl start ollama${NC}"
    exit 1
fi
echo -e "${GREEN}Ollama server is active.${NC}"

# --- Main Menu Loop ---
while true; do
    echo -e "\n${BLUE}--- Ollama Model Manager ---${NC}"
    echo "1. Load models (up to 2)"
    echo "2. Unload a model"
    echo "3. View running models"
    echo "4. Exit"
    echo -n "Enter your choice (1-4): "
    read choice

    case $choice in
        1)
            load_models
            ;;
        2)
            unload_model
            ;;
        3)
            view_models
            ;;
        4)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Please enter a number from 1 to 4.${NC}"
            ;;
    esac
done