#!/bin/bash

# Cargar el archivo de configuración
source config.sh

# Función para manejar errores
handle_error() {
  echo "Error: $1"
  exit 1
}

# Crear directorios necesarios
echo "Creando directorios necesarios..."
mkdir -p "$ODOO_HOME" "$ODOO_SERVER" "$ODOO_LOG_DIR" "$ODOO_ADDONS_DIR"
check_success

# Clonar el repositorio de Odoo
echo "Clonando el repositorio de Odoo..."
if [ ! -d "$ODOO_SERVER/.git" ]; then
  git clone --depth 1 --branch "$ODOO_VERSION" "$ODOO_REPO" "$ODOO_SERVER"
  check_success
else
  echo "El repositorio de Odoo ya está clonado."
fi

# Verificar e instalar python3-venv si no está instalado
echo "Verificando e instalando python3-venv..."
if ! dpkg -l | grep -q "python3-venv"; then
  sudo apt install python3-venv -y || handle_error "No se pudo instalar python3-venv."
else
  echo "python3-venv ya está instalado."
fi

# Crear un entorno virtual
echo "Creando entorno virtual..."
if [ ! -d "$ODOO_SERVER/venv" ]; then
  python3 -m venv "$ODOO_SERVER/venv"
  if [ $? -ne 0 ]; then
    handle_error "No se pudo crear el entorno virtual."
  fi
  echo "Entorno virtual creado correctamente."
else
  echo "El entorno virtual ya existe."
  # Verificar si el archivo 'activate' existe
  if [ ! -f "$ODOO_SERVER/venv/bin/activate" ] && [ ! -f "$ODOO_SERVER/venv/Scripts/activate" ]; then
    echo "El archivo 'activate' no existe. Eliminando y recreando el entorno virtual..."
    rm -rf "$ODOO_SERVER/venv"
    python3 -m venv "$ODOO_SERVER/venv" || handle_error "No se pudo recrear el entorno virtual."
  fi
fi

# Activar el entorno virtual
echo "Activando el entorno virtual..."
if [ -f "$ODOO_SERVER/venv/bin/activate" ]; then
  source "$ODOO_SERVER/venv/bin/activate"
elif [ -f "$ODOO_SERVER/venv/Scripts/activate" ]; then
  source "$ODOO_SERVER/venv/Scripts/activate"
else
  handle_error "No se encontró el archivo 'activate' en el entorno virtual."
fi

# Instalar dependencias del sistema para psycopg2 y python-ldap
echo "Instalando dependencias del sistema..."
sudo apt update
sudo apt install -y libpq-dev libldap2-dev libsasl2-dev libssl-dev || handle_error "No se pudieron instalar las dependencias del sistema."

# Ejecutar debinstall.sh para instalar dependencias adicionales
echo "Ejecutando debinstall.sh para instalar dependencias adicionales..."
if [ -f "$ODOO_SERVER/setup/debinstall.sh" ]; then
  sudo "$ODOO_SERVER/setup/debinstall.sh" || handle_error "No se pudo ejecutar debinstall.sh."
else
  echo "El archivo debinstall.sh no existe. Continuando sin ejecutarlo."
fi

# Instalar dependencias de Python
echo "Instalando dependencias de Python..."
pip install --upgrade pip || handle_error "No se pudo actualizar pip."

# Intentar instalar psycopg2 y python-ldap desde el código fuente
echo "Intentando instalar psycopg2 y python-ldap desde el código fuente..."
pip install psycopg2 python-ldap || {
  echo "No se pudieron instalar psycopg2 y python-ldap desde el código fuente. Instalando versiones precompiladas..."
  pip install psycopg2-binary python-ldap || handle_error "No se pudieron instalar las versiones precompiladas."
}

# Instalar el resto de dependencias desde requirements.txt
echo "Instalando el resto de dependencias desde requirements.txt..."
pip install -r "$ODOO_SERVER/requirements.txt" || handle_error "No se pudieron instalar las dependencias de Python."

# Crear archivo de configuración de Odoo
echo "Creando archivo de configuración de Odoo..."
cat <<EOL > "$ODOO_CONFIG_FILE"
[options]
; Configuración básica
admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = $DB_USER
db_password = $DB_PASS
addons_path = $ODOO_ADDONS_DIR,$ODOO_SERVER/addons
logfile = $ODOO_LOG_DIR/odoo.log
EOL
check_success

echo "Instalación completada."
