# 📋 GUÍA COMPLETA WINDOWS: Taller Vagrant + Ansible (3 VMs)

## 🎯 Objetivo
Desplegar un **Sistema de Exámenes Médicos completo** usando **3 máquinas virtuales esenciales** en Windows + VirtualBox:

1. **🐘 Database:** PostgreSQL 15 con datos médicos
2. **🌐 Web Server:** PHP 8.3 + CakePHP 5 + Nginx  
3. **⚖️ Load Balancer:** Nginx como proxy reverso

**⚡ Tiempo estimado:** 10-15 minutos | **💾 Recursos:** ~4GB RAM | **🎯 Enfoque:** Solo lo esencial

---

## 📋 PRERREQUISITOS

### Windows 10/11 + PowerShell como Administrador
```powershell
# Instalar Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex

# Instalar herramientas
choco install -y virtualbox vagrant git
# (Opcional) Cliente PostgreSQL para pruebas
choco install -y postgresql
```

### Verificar instalación
```powershell
vagrant --version    # Debe mostrar Vagrant 2.4.9+
VBoxManage --version # Debe mostrar VirtualBox 7.x
```

---

## 🚨 PATRÓN COMÚN: Problema SSH Timeout en Windows

**Problema frecuente:** Las VMs fallan con timeout SSH en el primer `vagrant up`

**Solución universal:**
```powershell
vagrant reload [nombre_vm]   # Reinicia y ejecuta provisioning automáticamente
```

**Por qué pasa:** Windows + VirtualBox tiene problemas de timing en el primer boot  
**Por qué funciona:** `vagrant reload` reinicia correctamente y soluciona SSH

---

## FASE 1: MÁQUINA VIRTUAL DE BASE DE DATOS

### Paso 1.1: Levantar Database VM
```powershell
vagrant up database
```

#### 🚨 Si falla con SSH timeout:
```powershell
vagrant reload database
```

#### 🚨 Si los datos están vacíos después:
```powershell
vagrant provision database
```

### Paso 1.2: Verificar PostgreSQL
```powershell
# Verificar estado
vagrant status database
# Resultado: running (virtualbox)

# Verificar servicio PostgreSQL
vagrant ssh database -c "sudo systemctl status postgresql --no-pager"
# Resultado: Active: active (running)
```

### Paso 1.3: Verificar datos desde la VM
```powershell
vagrant ssh database

# Dentro de la VM:
sudo -u postgres psql -d examenes_db
\dt                                    # Ver tablas
SELECT email, role FROM users;        # Ver usuarios
SELECT COUNT(*) FROM reactivos;       # Contar preguntas
\q
exit
```

**Resultado esperado:** Tablas `users`, `reactivos`, `examenes` con datos

### Paso 1.4: Verificar conectividad desde Windows
```powershell
# El puerto es 5434 (no 5433) para evitar conflictos
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5434 -U examenes_user -d examenes_db -c "\dt"
```

#### 🚨 Si falla "permission denied for table":
```powershell
vagrant ssh database

# Dentro de la VM:
sudo -u postgres psql -d examenes_db
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO examenes_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO examenes_user;
\q
exit
```

---

## FASE 2: SERVIDOR WEB

### Paso 2.1: Levantar Web Server VM
```powershell
vagrant up webserver
```

#### 🚨 Si falla con SSH timeout:
```powershell
vagrant reload webserver
```

### Paso 2.2: Verificar servicios web
```powershell
# Verificar Nginx
vagrant ssh webserver -c "sudo systemctl status nginx --no-pager"
# Resultado: Active: active (running)

# Verificar PHP-FPM
vagrant ssh webserver -c "sudo systemctl status php8.3-fpm --no-pager"
# Resultado: Active: active (running)
```

### Paso 2.3: Verificar aplicación
```powershell
# Verificar que se clonó la aplicación
vagrant ssh webserver -c "ls -la /var/www/examenes_sistema/"
# Resultado: Archivos de CakePHP (src/, config/, webroot/, etc.)

# Probar respuesta HTTP
vagrant ssh webserver -c "curl -s -o /dev/null -w '%{http_code}' http://localhost/"
# Resultado esperado: 302 (redirect)
```

#### 🚨 Si devuelve error 500 (dependencias faltantes):
```powershell
# Instalar dependencias de CakePHP con Composer
vagrant ssh webserver -c "sudo -u www-data composer install --working-dir=/var/www/examenes_sistema --no-dev --optimize-autoloader"

# Verificar que funcionó
vagrant ssh webserver -c "curl -s -o /dev/null -w '%{http_code}' http://localhost/"
# Resultado: 302 (¡funciona!)
```

### Paso 2.4: Probar aplicación desde Windows
```powershell
# Abrir aplicación directamente
start http://192.168.56.20
```

#### 🚨 Si hay errores de base de datos:
**Errores típicos:**
- `permission denied for schema public`
- `Columns used in constraints must be added to the Table schema first`

**Solución completa:**
```powershell
# 1. Otorgar permisos de esquema PostgreSQL
vagrant ssh database -c 'sudo -u postgres psql -d examenes_db -c "GRANT ALL PRIVILEGES ON SCHEMA public TO examenes_user;"'

# 2. Otorgar permisos para tablas futuras  
vagrant ssh database -c 'sudo -u postgres psql -d examenes_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO examenes_user;"'

# 3. Arreglar permisos de logs en CakePHP
vagrant ssh webserver -c "sudo chmod -R 777 /var/www/examenes_sistema/logs && sudo chown -R www-data:www-data /var/www/examenes_sistema/logs"

# 4. Limpiar y regenerar caché de esquemas de CakePHP
vagrant ssh webserver -c "cd /var/www/examenes_sistema && bin/cake schema_cache clear"
vagrant ssh webserver -c "cd /var/www/examenes_sistema && bin/cake schema_cache build"
```

---

## FASE 3: LOAD BALANCER

### Paso 3.1: Levantar Load Balancer VM
```powershell
vagrant up loadbalancer
```

#### 🚨 Si falla con SSH timeout:
```powershell
vagrant reload loadbalancer
```

### Paso 3.2: Verificar Load Balancer
```powershell
# Verificar Nginx
vagrant ssh loadbalancer -c "sudo systemctl status nginx --no-pager"
# Resultado: Active: active (running)

# Verificar configuración
vagrant ssh loadbalancer -c "sudo nginx -t"
# Resultado: nginx: configuration file test is successful

# Verificar conectividad al webserver
vagrant ssh loadbalancer -c "nc -zv -w3 192.168.56.20 80"
# Resultado: Connection succeeded
```

### Paso 3.3: Probar desde Windows
```powershell
# Probar Load Balancer
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object -ExpandProperty StatusCode
# Resultado: 200

# Abrir en navegador (¡ACCESO PRINCIPAL!)
start http://localhost:8080
```

---

## ✅ VERIFICACIÓN FINAL DEL SISTEMA

### Estado de las VMs
```powershell
vagrant status
# Todas deben mostrar: running (virtualbox)
```

### Conectividad entre VMs
```powershell
# Web Server → Database
vagrant ssh webserver -c "nc -zv -w3 192.168.56.30 5432"
# Load Balancer → Web Server  
vagrant ssh loadbalancer -c "nc -zv -w3 192.168.56.20 80"
```

### Pruebas funcionales
```powershell
# 1. Base de datos desde Windows
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5434 -U examenes_user -d examenes_db -c "SELECT email FROM users LIMIT 3;"

# 2. Aplicación web funcionando
start http://localhost:8080

# 3. Load balancer distribuyendo correctamente
for($i=1; $i -le 5; $i++) {
    Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object StatusCode
    Start-Sleep 1
}
```

---

## 🔐 CREDENCIALES DEL SISTEMA

### Para login en la aplicación web:
- **URL:** http://localhost:8080/login
- **Email:** admin@examenes.com  
- **Password:** admin123

### Para base de datos:
- **Host:** localhost:5434
- **Usuario:** examenes_user
- **Password:** examenes_password_123
- **Database:** examenes_db

---

## 📊 RESUMEN DE SERVICIOS

| VM | IP | Servicio | Puerto | Acceso desde Windows |
|---|---|---|---|---|
| **database** | 192.168.56.30 | PostgreSQL | 5432 | localhost:5434 |
| **webserver** | 192.168.56.20 | Nginx + PHP + CakePHP | 80 | Directo o vía LB |
| **loadbalancer** | 192.168.56.10 | Nginx Proxy | 80 | **http://localhost:8080** |

---

## 🏆 CHECKLIST FINAL

### Database VM (192.168.56.30)
- [ ] PostgreSQL service active
- [ ] Base de datos `examenes_db` creada
- [ ] Usuario `examenes_user` con permisos completos
- [ ] Puerto 5434 accesible desde Windows
- [ ] Tablas del sistema creadas (users, reactivos, examenes)
- [ ] Datos de prueba insertados

### Web Server VM (192.168.56.20)
- [ ] Nginx service active
- [ ] PHP 8.3-FPM service active
- [ ] Aplicación clonada en `/var/www/examenes_sistema`
- [ ] Dependencias Composer instaladas
- [ ] Configuración de base de datos correcta
- [ ] Permisos de archivos configurados
- [ ] Respuesta HTTP 302 local
- [ ] Caché de esquemas limpio

### Load Balancer VM (192.168.56.10)
- [ ] Nginx service active
- [ ] Configuración de proxy correcta
- [ ] Conectividad al webserver
- [ ] Puerto 8080 accesible desde Windows
- [ ] Página de la aplicación carga correctamente

---

## 🎯 RESULTADO FINAL

### Lo que debes ver:
1. **http://localhost:8080** - Sistema de Exámenes Médicos funcionando
2. **localhost:5434** - PostgreSQL accesible desde Windows
3. **VirtualBox** - 3 VMs corriendo sin errores

### Aplicación funcional:
- ✅ Login con credenciales
- ✅ Sin errores de base de datos
- ✅ Navegación fluida
- ✅ Datos de prueba disponibles

---

## 🔧 TROUBLESHOOTING RÁPIDO

### Comando universal para problemas SSH:
```powershell
vagrant reload [vm_name]
```

### Ver puertos en uso:
```powershell
netstat -ano | findstr :8080
netstat -ano | findstr :5434
```

### Probar conectividad:
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5434  # PostgreSQL
Test-NetConnection -ComputerName 127.0.0.1 -Port 8080  # Load Balancer
```

### Reiniciar con re-provisionamiento:
```powershell
vagrant reload database --provision
vagrant reload webserver --provision
vagrant reload loadbalancer --provision
```

### Verificar logs:
```powershell
vagrant ssh database -c "sudo journalctl -u postgresql -f"
vagrant ssh webserver -c "sudo tail -f /var/log/nginx/error.log"
vagrant ssh loadbalancer -c "sudo tail -f /var/log/nginx/access.log"
```

---

## 🎉 ¡TALLER COMPLETADO!

**¡Felicidades!** Has desplegado exitosamente:
- 🐘 **PostgreSQL 15** con datos médicos
- 🌐 **CakePHP 5** con PHP 8.3
- ⚖️ **Load Balancer** con Nginx
- 🔗 **Integración completa** funcionando

**Tu Sistema de Exámenes Médicos está corriendo en una infraestructura profesional de 3 capas.**

---

**Autor:** Andrei Erik Rodrigo Díaz Rosario  
**Fecha:** Septiembre 2024  
**Tecnologías:** Vagrant, Ansible, VirtualBox, CakePHP 5, PostgreSQL 15