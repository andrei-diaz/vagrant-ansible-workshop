#!/bin/bash
# Script de aprovisionamiento para la VM database
# Sistema de Exámenes Médicos

echo "=== 🐘 CONFIGURANDO POSTGRESQL ==="

# Actualizar sistema
apt-get update -y

# Instalar PostgreSQL y dependencias
apt-get install -y postgresql postgresql-contrib python3-psycopg2

# Configurar PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configurar usuario y base de datos
sudo -u postgres psql -c "CREATE DATABASE examenes_db;"
sudo -u postgres psql -c "CREATE USER examenes_user WITH PASSWORD 'examenes_password_123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE examenes_db TO examenes_user;"
sudo -u postgres psql -c "ALTER USER examenes_user CREATEDB;"

# Configurar acceso remoto
echo "host    all             all             10.0.2.0/24            md5" >> /etc/postgresql/*/main/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Reiniciar PostgreSQL
systemctl restart postgresql

# Crear tablas básicas
sudo -u postgres psql -d examenes_db << 'EOF'
-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'estudiante',
    active BOOLEAN DEFAULT true,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de reactivos (preguntas)
CREATE TABLE IF NOT EXISTS reactivos (
    id SERIAL PRIMARY KEY,
    pregunta TEXT NOT NULL,
    respuesta_a VARCHAR(500) NOT NULL,
    respuesta_b VARCHAR(500) NOT NULL,
    respuesta_c VARCHAR(500) NOT NULL,
    respuesta_correcta CHAR(1) NOT NULL CHECK (respuesta_correcta IN ('a', 'b', 'c')),
    retroalimentacion TEXT,
    dificultad VARCHAR(20) DEFAULT 'medio',
    area_especialidad VARCHAR(100),
    subespecialidad VARCHAR(100),
    user_id INTEGER,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usuario administrador
INSERT INTO users (email, password, role, active) VALUES 
('admin@examenes.com', 'admin123', 'administrador', true)
ON CONFLICT (email) DO NOTHING;

-- Datos de prueba
INSERT INTO reactivos (pregunta, respuesta_a, respuesta_b, respuesta_c, respuesta_correcta, area_especialidad, subespecialidad, user_id) VALUES
('¿Cuál es la dosis inicial recomendada de aspirina para prevención cardiovascular?', '75-100 mg/día', '200-300 mg/día', '500-1000 mg/día', 'a', 'Medicina Interna', 'Cardiología', 1),
('¿Cuál es el signo patognomónico de apendicitis aguda?', 'Signo de McBurney', 'Signo de Murphy', 'Signo de Rovsing', 'a', 'Cirugía', 'Cirugía General', 1),
('¿A qué edad se recomienda iniciar el tamizaje de cáncer cervicouterino?', '18 años', '21 años', '25 años', 'b', 'Ginecología', 'Oncología Ginecológica', 1)
ON CONFLICT DO NOTHING;
EOF

# Configurar backup automático
echo "0 2 * * * postgres pg_dump examenes_db | gzip > /var/backups/examenes_$(date +\%Y\%m\%d).sql.gz" >> /etc/crontab

# Crear directorio de backups
mkdir -p /var/backups
chown postgres:postgres /var/backups

echo "=== ✅ POSTGRESQL CONFIGURADO ==="
echo "📊 Base de datos: examenes_db"
echo "👤 Usuario: examenes_user" 
echo "🔑 Password: examenes_password_123"
echo "🌐 Host: localhost (dentro de la VM)"

# Mostrar estado
systemctl status postgresql --no-pager -l