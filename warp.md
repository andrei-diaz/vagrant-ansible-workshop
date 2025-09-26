# Warp.md - Vagrant + Ansible Workshop: Sistema de Exámenes Médicos

## 🎯 Propósito del Proyecto
Esta es una infraestructura completa como código (IaC) que demuestra el despliegue automatizado de un sistema de exámenes médicos usando Vagrant + Ansible. El proyecto crea una arquitectura distribuida de 5 máquinas virtuales con aprovisionamiento automático completo.

## 🏗️ Arquitectura y Componentes

### Máquinas Virtuales
- **Load Balancer** (`192.168.56.10`): Nginx como proxy reverso
- **Web Server** (`192.168.56.20`): PHP 8.3 + CakePHP 5 + Nginx
- **Database** (`192.168.56.30`): PostgreSQL 15
- **Monitoring** (`192.168.56.40`): Grafana + Prometheus + Node Exporter
- **Orchestrator** (`192.168.56.50`): Nodo de control Ansible

### Aplicación Integrada
- **Repositorio de la aplicación**: `https://github.com/andrei-diaz/examenes_sistema.git`
- **Framework**: CakePHP 5
- **Base de datos**: PostgreSQL con datos de prueba médicos
- **Clonado automático**: El Vagrantfile clona automáticamente la aplicación

## 📁 Estructura del Proyecto

### Archivos Principales
- `Vagrantfile`: Configuración completa de las 5 VMs con VirtualBox para Windows
- `README.md`: Documentación principal del usuario
- `.gitignore`: Configurado para excluir archivos de Vagrant y temporales

### Guías y Documentación
- `GUIA_PASO_A_PASO.md`: Guía detallada para macOS + QEMU
- `GUIA_PASO_A_PASO_WINDOWS.md`: Guía específica para Windows + VirtualBox
- `SOLUCION_PROBLEMAS_COMUNES.md`: Troubleshooting y soluciones
- `warp.md`: Este archivo de indexación

### Scripts de Aprovisionamiento
- `provision_database.sh`: Script de provisión manual para PostgreSQL

## 🔧 Configuración de Ansible

### Estructura Ansible
```
ansible/
├── site.yml                 # Playbook principal orquestador
├── database.yml             # Configuración PostgreSQL + datos de prueba
├── web_server.yml           # PHP 8.3 + CakePHP 5 + Nginx
├── load_balancer.yml        # Nginx como proxy reverso
├── monitoring.yml           # Grafana + Prometheus stack
├── group_vars/all.yml       # Variables globales del proyecto
└── inventory/hosts          # Inventario de servidores
```

### Variables Clave (ansible/group_vars/all.yml)
- **Proyecto**: `examenes_sistema`
- **Red**: `192.168.56.0/24`
- **Base de datos**: PostgreSQL 15, usuario: `examenes_user`
- **PHP**: Versión 8.3, memoria: 256M
- **Monitoreo**: Grafana (3000), Prometheus (9090)
- **Usuarios de prueba**: admin, profesor, estudiante
- **Especialidades médicas**: Medicina Interna, Cirugía, Pediatría, Ginecología

## 🚀 Casos de Uso y Funcionalidades

### DevOps y Automatización
- Infraestructura como código completa
- Aprovisionamiento automático multi-VM
- Configuración de servicios automatizada
- Health checks y verificaciones
- Logs centralizados y rotación automática

### Desarrollo de Aplicaciones
- Entorno de desarrollo distribuido
- Base de datos con datos de prueba médicos
- Sincronización automática de código desde GitHub
- Configuración automática de CakePHP 5
- Balanceador de carga funcional

### Monitoreo y Observabilidad
- Stack completo Prometheus + Grafana
- Métricas de sistema y aplicación
- Dashboards predefinidos
- Node Exporter en todas las VMs

## 🔐 Configuración de Seguridad
- **Base de datos**: Usuario dedicado con contraseña específica
- **Aplicación**: Salt de seguridad generado automáticamente
- **Usuarios del sistema**: 3 roles (admin, profesor, estudiante)
- **Nginx**: Headers de seguridad configurados
- **SSH**: Llaves automáticas para comunicación entre VMs

## 🌐 Acceso a Servicios
- **Aplicación principal**: `http://localhost:8080`
- **Acceso directo web**: `http://192.168.56.20`
- **Grafana**: `http://localhost:3000` (admin/admin)
- **Prometheus**: `http://localhost:9090`
- **PostgreSQL**: `localhost:5433` (examenes_user/examenes_password_123)

## 💻 Compatibilidad Multiplataforma
- **Windows 10/11**: VirtualBox (configuración actual)
- **macOS**: Intel/M1/M2 con QEMU (configuración alternativa)
- **Linux**: VirtualBox/QEMU

## 📊 Datos de Prueba Incluidos
- **Especialidades médicas**: 4 especialidades principales
- **Subespecialidades**: 12 subespecialidades distribuidas
- **Usuarios**: 3 tipos de usuarios con roles específicos
- **Base de datos**: Estructura completa para sistema de exámenes

## 🛠️ Comandos Principales
- `vagrant up`: Levantar toda la infraestructura
- `vagrant status`: Ver estado de las VMs
- `vagrant ssh [vm]`: Conectar a una VM específica
- `vagrant destroy -f`: Destruir toda la infraestructura

## 📝 Características Técnicas Destacadas
- **Clonado automático**: No requiere descargar la aplicación manualmente
- **Configuración automática**: Base de datos, usuarios, permisos
- **Health checks**: Scripts de verificación incluidos
- **Performance**: Configuraciones optimizadas para desarrollo
- **Logs**: Rotación automática y gestión de logs
- **Backup**: Configuración de respaldos automáticos

## 🎓 Valor Educativo
Este proyecto es ideal para:
- **Aprender DevOps**: Infraestructura como código
- **Practicar Ansible**: Playbooks complejos y orquestación
- **Entender arquitecturas distribuidas**: Separación de servicios
- **Monitoreo**: Stack completo de observabilidad
- **Desarrollo PHP/CakePHP**: Entorno real de desarrollo

## 🔄 Integración Continua
- **GitHub Integration**: Clonado automático desde repositorio
- **Configuration Management**: Ansible para toda la configuración
- **Infrastructure as Code**: Vagrantfile versionado
- **Automated Testing**: Health checks y verificaciones automáticas