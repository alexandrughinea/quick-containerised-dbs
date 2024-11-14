#!/bin/bash

# Function to prompt the user for action (add or remove)
prompt_action() {
    echo "Would you like to add or remove a PostgreSQL user?"
    select action in "Add" "Remove" "Quit"; do
        case $action in
            Add ) ACTION="add"; break;;
            Remove ) ACTION="remove"; break;;
            Quit ) exit;;
        esac
    done
}

# Function to prompt for general inputs
prompt_input() {
    read -p "Enter Docker container name: " DOCKER_CONTAINER_NAME
    read -p "Enter PostgreSQL database name: " DB_NAME
    read -p "Enter PostgreSQL superuser name: " PG_USER
    read -s -p "Enter PostgreSQL superuser password: " PG_PASSWORD  # -s hides input for passwords
    echo  # New line after password input
}

# Function to prompt for add-user specific inputs
prompt_add_user() {
    read -p "Enter new username to add: " NEW_USERNAME
    read -s -p "Enter new password for the user: " NEW_PASSWORD  # -s hides input for passwords
    echo  # New line after password input
}

# Function to prompt for remove-user specific inputs
prompt_remove_user() {
    read -p "Enter username to remove: " REMOVE_USERNAME
}

# Function to add a new user
add_user() {
    echo "Adding user '$NEW_USERNAME' to PostgreSQL database '$DB_NAME' in container '$DOCKER_CONTAINER_NAME'..."

    # Use the provided superuser credentials to connect and create a new user
    docker exec -e PGPASSWORD="$PG_PASSWORD" -it "$DOCKER_CONTAINER_NAME" psql -U "$PG_USER" -d "$DB_NAME" -c "
    CREATE USER $NEW_USERNAME WITH PASSWORD '$NEW_PASSWORD';
    GRANT CONNECT ON DATABASE $DB_NAME TO $NEW_USERNAME;
    GRANT USAGE ON SCHEMA public TO $NEW_USERNAME;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $NEW_USERNAME;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $NEW_USERNAME;
    "
    echo "User '$NEW_USERNAME' has been added successfully to '$DB_NAME'."
}

# Function to remove a user forcefully
remove_user() {
    echo "Removing user '$REMOVE_USERNAME' from PostgreSQL database '$DB_NAME' in container '$DOCKER_CONTAINER_NAME'..."

    # Use the provided superuser credentials to revoke privileges, reassign ownership, and drop the user
    docker exec -e PGPASSWORD="$PG_PASSWORD" -it "$DOCKER_CONTAINER_NAME" psql -U "$PG_USER" -d "$DB_NAME" -c "
    -- Revoke all privileges
    REVOKE ALL PRIVILEGES ON DATABASE $DB_NAME FROM $REMOVE_USERNAME;
    
    -- Reassign all owned objects to the superuser (or another user of your choice)
    REASSIGN OWNED BY $REMOVE_USERNAME TO $PG_USER;
    
    -- Drop any objects owned by the user (if not reassigned)
    DROP OWNED BY $REMOVE_USERNAME;

    -- Finally, drop the user
    DROP USER $REMOVE_USERNAME;
    "
    echo "User '$REMOVE_USERNAME' has been removed successfully from '$DB_NAME'."
}

# Main script logic
prompt_action  # Ask whether to add or remove a user
prompt_input   # Get general inputs (container, DB, superuser)

if [ "$ACTION" = "add" ]; then
    prompt_add_user  # Get add-user specific inputs
    add_user         # Call add user function
elif [ "$ACTION" = "remove" ]; then
    prompt_remove_user  # Get remove-user specific inputs
    remove_user         # Call remove user function
fi
