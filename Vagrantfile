# -*- mode: ruby -*-
# vi: set ft=ruby :

# Taller Vagrant + Ansible: Sistema de Exámenes Médicos
# Arquitectura Multi-VM con aprovisionamiento automatizado
# Configurado para Windows + VirtualBox

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Box x86_64 compatible con VirtualBox en Windows
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  
  # Configuración global para VirtualBox
  config.vm.provider "virtualbox" do |vb|
    # Habilitar GUI si es necesario (descomentrar la siguiente línea)
    # vb.gui = true
    
    # Configuraciones de red y sistema
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
  
  # Configuración de SSH para Windows
  config.ssh.forward_agent = true
  config.ssh.insert_key = false

  # ===========================================
  # LOAD BALANCER - Nginx Proxy Reverso
  # ===========================================
  config.vm.define "loadbalancer" do |lb|
    lb.vm.hostname = "examenes-lb"
    lb.vm.network "private_network", ip: "192.168.56.10"
    lb.vm.network "forwarded_port", guest: 22, host: 50021, auto_correct: true
    lb.vm.network "forwarded_port", guest: 80, host: 8080
    
    lb.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-lb"
      vb.memory = 512
      vb.cpus = 1
    end
    
    # Provision con Ansible
    lb.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/load_balancer.yml"
      ansible.inventory_path = "ansible/inventory/hosts"
      ansible.limit = "loadbalancer"
    end
  end

  # ===========================================
  # WEB SERVER - PHP + CakePHP 5
  # ===========================================
  config.vm.define "webserver" do |web|
    web.vm.hostname = "examenes-web"
    web.vm.network "private_network", ip: "192.168.56.20"
    web.vm.network "forwarded_port", guest: 22, host: 50023, auto_correct: true
    
    web.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-web"
      vb.memory = 2048
      vb.cpus = 2
    end
    
    # Sincronización del código fuente del proyecto
    # IMPORTANTE: Cambiar esta ruta por la ruta de tu proyecto en Windows
    # Ejemplo: "C:/Users/TuUsuario/Documents/examenes_sistema"
    web.vm.synced_folder "./app", "/var/www/examenes_sistema", 
      create: true,
      type: "virtualbox",
      owner: "www-data", group: "www-data"
    
    web.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/web_server.yml"
      ansible.inventory_path = "ansible/inventory/hosts"
      ansible.limit = "webservers"
      ansible.extra_vars = {
        app_name: "examenes_sistema",
        php_version: "8.3",
        app_env: "development"
      }
    end
  end

  # ===========================================
  # DATABASE SERVER - PostgreSQL
  # ===========================================
  config.vm.define "database" do |db|
    db.vm.hostname = "examenes-db"
    db.vm.network "private_network", ip: "192.168.56.30"
    db.vm.network "forwarded_port", guest: 22, host: 50022, auto_correct: true
    db.vm.network "forwarded_port", guest: 5432, host: 5433
    
    db.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-db"
      vb.memory = 1536
      vb.cpus = 2
    end
    
    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/database.yml"
      ansible.inventory_path = "ansible/inventory/hosts"
      ansible.limit = "database"
      ansible.extra_vars = {
        db_name: "examenes_db",
        db_user: "examenes_user",
        db_password: "examenes_password_123",
        postgres_version: "15"
      }
    end
  end

  # ===========================================
  # MONITORING - Grafana + Prometheus
  # ===========================================
  config.vm.define "monitoring" do |mon|
    mon.vm.hostname = "examenes-monitoring"
    mon.vm.network "private_network", ip: "192.168.56.40"
    mon.vm.network "forwarded_port", guest: 22, host: 50024, auto_correct: true
    mon.vm.network "forwarded_port", guest: 3000, host: 3000  # Grafana
    mon.vm.network "forwarded_port", guest: 9090, host: 9090  # Prometheus
    
    mon.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-monitoring"
      vb.memory = 1024
      vb.cpus = 2
    end
    
    mon.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/monitoring.yml"
      ansible.inventory_path = "ansible/inventory/hosts"
      ansible.limit = "monitoring"
    end
  end

  # ===========================================
  # PROVISION ORCHESTRATOR
  # ===========================================
  config.vm.define "orchestrator", primary: true do |orch|
    orch.vm.hostname = "examenes-orchestrator"
    orch.vm.network "private_network", ip: "192.168.56.50"
    orch.vm.network "forwarded_port", guest: 22, host: 50025, auto_correct: true
    
    orch.vm.provider "virtualbox" do |vb|
      vb.name = "examenes-orchestrator"
      vb.memory = 512
      vb.cpus = 1
    end
    
    # Ejecutar playbook principal después de que todas las VMs estén listas
    orch.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/site.yml"
      ansible.inventory_path = "ansible/inventory/hosts"
      ansible.limit = "all"
      ansible.extra_vars = {
        deploy_timestamp: Time.now.strftime("%Y%m%d-%H%M%S")
      }
    end
  end
end