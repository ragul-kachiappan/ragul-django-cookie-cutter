#!/bin/bash
# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and catch errors in pipelines.
set -euo pipefail

#####################################
#       CONFIGURATION SECTION       #
#####################################
# Edit these variables for each project deployment

# Home directory (will use $HOME for portability)
HOME_DIR="$HOME"

# Project-specific variables
PROJECT_NAME="your-django-project"         # e.g., "midalloy-poc-internal"
REPO_URL="https://github.com/username/your-django-project.git"
BRANCH="main"                              # e.g., "feat/sse" or "main"

# Optional components: Set these to "true" if your project uses them
OPTIONAL_VECTOR_DB="false"  # If your project has a directory (e.g., "vector_db") to preserve
OPTIONAL_SQLITE_DB="false"  # If your project uses a sqlite file (e.g., "db.sqlite3") to preserve

# Relative paths (from the project root) to the optional components.
VECTOR_DB_DIR="vector_db"
SQLITE_DB_FILE="db.sqlite3"

# Common configuration directory (for example, containing your .env file and Apache configs)
COMMON_CONFIG_DIR="${HOME_DIR}/common_scripts"

# Deployment directories
PROJECT_DIR="${HOME_DIR}/${PROJECT_NAME}"   # Where the repo will be cloned
VENV_DIR="${PROJECT_DIR}/venv"                # Virtual environment directory
LOG_DIR="/var/log/${PROJECT_NAME}"            # Log directory for this project

#####################################
#       BEGIN DEPLOYMENT            #
#####################################

echo "Starting deployment for project: ${PROJECT_NAME}"

#############################################
# 1. Preserve Optional Data (if applicable) #
#############################################

if [ "${OPTIONAL_VECTOR_DB}" = "true" ]; then
  echo "Preserving optional vector database directory (${VECTOR_DB_DIR})..."
  rm -rf "${HOME_DIR:?}/${VECTOR_DB_DIR}"
  cp -r "${PROJECT_DIR:?}/${VECTOR_DB_DIR}" "${HOME_DIR}/"
  # Set safe permissions: directories 755, files 644
  find "${HOME_DIR}/${VECTOR_DB_DIR}" -type d -exec chmod 755 {} +
  find "${HOME_DIR}/${VECTOR_DB_DIR}" -type f -exec chmod 644 {} +
fi

if [ "${OPTIONAL_SQLITE_DB}" = "true" ]; then
  echo "Preserving optional SQLite database file (${SQLITE_DB_FILE})..."
  rm -f "${HOME_DIR:?}/${SQLITE_DB_FILE}"
  cp "${PROJECT_DIR:?}/${SQLITE_DB_FILE}" "${HOME_DIR}/"
  chmod 644 "${HOME_DIR:?}/${SQLITE_DB_FILE}"
fi

#############################################
# 2. Clone the Latest Repository Version    #
#############################################

echo "Cloning repository from ${REPO_URL} (branch: ${BRANCH})..."
rm -rf "${PROJECT_DIR}"
git clone -b "${BRANCH}" "${REPO_URL}" "${PROJECT_DIR}"

#############################################
# 3. Restore Preserved Data (if applicable)   #
#############################################

if [ "${OPTIONAL_VECTOR_DB}" = "true" ]; then
  echo "Restoring vector database directory..."
  cp -r "${HOME_DIR}/${VECTOR_DB_DIR}" "${PROJECT_DIR}/"
  find "${PROJECT_DIR}/${VECTOR_DB_DIR}" -type d -exec chmod 755 {} +
  find "${PROJECT_DIR}/${VECTOR_DB_DIR}" -type f -exec chmod 644 {} +
fi

if [ "${OPTIONAL_SQLITE_DB}" = "true" ]; then
  echo "Restoring SQLite database file..."
  cp "${HOME_DIR}/${SQLITE_DB_FILE}" "${PROJECT_DIR}/"
  chmod 644 "${PROJECT_DIR}/${SQLITE_DB_FILE}"
fi

#############################################
# 4. Copy Project Environment Configuration   #
#############################################

if [ -f "${COMMON_CONFIG_DIR}/.env" ]; then
  echo "Copying .env configuration file..."
  # Adjust the destination if your project expects .env in a subdirectory.
  cp "${COMMON_CONFIG_DIR}/.env" "${PROJECT_DIR}/"
fi

#############################################
# 5. Install System Dependencies            #
#############################################

echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    apache2 \
    libapache2-mod-wsgi-py3 \
    ffmpeg \
    wkhtmltopdf \
    xvfb \
    libpq-dev \
    binutils \
    libproj-dev \
    gdal-bin \
    libcurl4-openssl-dev \
    libssl-dev

#############################################
# 6. Set Up Log Directory                   #
#############################################

echo "Setting up log directory at ${LOG_DIR}..."
sudo mkdir -p "${LOG_DIR}"
sudo chown "$USER":"$USER" "${LOG_DIR}"
chmod 750 "${LOG_DIR}"

#############################################
# 7. Set Up Python Virtual Environment      #
#############################################

echo "Setting up Python virtual environment..."
cd "${PROJECT_DIR}"
python3 -m venv "${VENV_DIR}"
# Activate the virtual environment
# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"

# Upgrade pip (optional)
pip install --upgrade pip

#############################################
# 8. Install Python Dependencies            #
#############################################

if [ -f "requirements.txt" ]; then
  echo "Installing Python dependencies from requirements.txt..."
  pip install -r requirements.txt
else
  echo "No requirements.txt found. Please ensure Django and other dependencies are installed."
fi

#############################################
# 9. Django Management Commands             #
#############################################

if [ -f "manage.py" ]; then
  echo "Collecting static files..."
  python manage.py collectstatic --noinput

  echo "Applying database migrations..."
  python manage.py makemigrations
  python manage.py migrate

  # Optionally, load fixtures if they exist.
  # Adjust the fixture path if your project uses fixtures.
  if [ -d "app/fixtures" ]; then
    # Example: load a fixture if it exists
    if [ -f "app/fixtures/feature_flags.json" ]; then
      echo "Loading fixture: feature_flags.json..."
      python manage.py loaddata app/fixtures/feature_flags.json
    fi
  fi
else
  echo "manage.py not found. Skipping Django management commands."
fi

#############################################
# 10. Configure Apache2 and Restart Server  #
#############################################

echo "Configuring Apache2..."
if [ -f "${COMMON_CONFIG_DIR}/000-default.conf" ]; then
  sudo cp "${COMMON_CONFIG_DIR}/000-default.conf" /etc/apache2/sites-enabled/
fi

if [ -f "${COMMON_CONFIG_DIR}/default-ssl.conf" ]; then
  sudo cp "${COMMON_CONFIG_DIR}/default-ssl.conf" /etc/apache2/sites-available/
fi

echo "Restarting Apache2..."
sudo systemctl restart apache2

echo "Deployment for project ${PROJECT_NAME} completed successfully."
