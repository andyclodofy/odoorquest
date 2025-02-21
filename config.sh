#!/bin/bash

# Archivo de configuración para la instalación de Odoo 18

# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ODOO_USER="andy"  # Utiliza el usuario actual
ODOO_VERSION="18.0"
ODOO_PORT="8069"
DB_USER="odoo"  # Utiliza el usuario actual
DB_PASS="odoo"  # Utiliza el usuario actual
DB_NAME="odoo"
ODOO_REPO="https://github.com/odoo/odoo.git"

# Obtener el directorio de inicio del usuario Odoo
ODOO_USER_HOME=$(getent passwd "$ODOO_USER" | cut -d: -f6)

# Directorio base para Odoo
ODOO_BASE_DIR="$ODOO_USER_HOME/odoo"

# Directorios centralizados en el directorio del usuario actual
ODOO_HOME="$ODOO_BASE_DIR"  # Carpeta base en el directorio del usuario actual
ODOO_SERVER="$ODOO_HOME/odoo-server" # Carpeta para el repositorio
ODOO_LOG_DIR="$ODOO_HOME/logs"
ODOO_ADDONS_DIR="$ODOO_HOME/addons"
ODOO_CONFIG_FILE="$ODOO_HOME/odoo.conf"  # Archivo de configuración en ODOO_HOME

# Función para verificar si un comando tuvo éxito
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error en el paso anterior. Saliendo."
    exit 1
  fi
}
