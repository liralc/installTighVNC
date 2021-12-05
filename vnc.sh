#!/usr/bin/env bash
#
# vnc.sh - instalação e configuração do VNC
#
# E-mail:     liralc@gmail.com
# Autor:      Anderson Lira
# Manutenção: Anderson Lira
#
# ************************************************************************** #
#  Este programa faz a instalaçõa e configuração do Tigehvnc.
#
#  Exemplos de execução:
#      $ ./vnc.sh
#
# ************************************************************************** #
# Histórico:
#
#   v1.0 14/05/2021, Anderson Lira:
#       - Início do programa.
#
#   v1.1 17/05/2021, Anderson Lira:
#       - Inclusão de teste de root e inclusão de cores no alerta.
#
#   v1.2 15/06/2021, Anderson Lira:
#       - Inclusão de variável para colocar o nome do usuário.
# ************************************************************************** #
# Testado em:
#   bash 5.0.3
#   Debian 10.9
# ************************************************************************** #

# ======== VARIAVEIS ============================================================== #
read -p "Informo o nome do usuário: " USUARIO

aptConf="$(cat << EOF
APT::Default-Release "buster";
APT::Cache-Limit "10000000000";
EOF
)"

xstartupConf="$(cat << EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
vncconfig -nowin &
exec dbus-launch mate-session
EOF
)"

unitConf="$(cat << EOF
[Unit]
Description=Start TightVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$USUARIO
Group=$USUARIO
WorkingDirectory=/home/$USUARIO

PIDFile=/home/$USUARIO/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF
)"

VERDE="\033[32;1m"
VERMELHOP="\033[31;1;5m"
# =================================================================================== #

# ======== TESTES =================================================================== #
if [ ! $(ping www.google.com -c 3) > /dev/null ]
then
    echo -e "${VERDE}Para a instalação do VNC, a sua máquina precisa está conectada na internet. "
    exit 1
fi

if [ $(echo $UID) -ne 0 ]
then
    echo -e "${VERMELHOP}Você deve está com privilégios de ROOT para continuar com esse programa."
    exit 1
fi

if [ $(dpkg -l tightvncserver) ]
then
    echo -e "${VERDE}TightVNC já instalado nesta máquina."
    exit 1
fi
# =================================================================================== #

# ======== FUNCOES ================================================================== #
Atualizacao () {
    apt-get update ; apt-get upgrade -y ; apt-get dist-upgrade -y ; apt autoremove
}

Pacotes () {
    apt-get install tightvncserver xtightvncviewer x11vnc -y
}
# =================================================================================== #

# ======== EXECUCAO ================================================================= #
echo "$aptConf" > /etc/apt/apt.conf
Atualizacao
Pacotes
# Nesse momento irá pedir para que o usuário insira a sua senha.
echo "Peça para que o USUÁRIO insira a senha dele."
su -c vncserver -s /bin/bash $USUARIO
mv /home/$USUARIO/.vnc/xstartup /home/$USUARIO/.vnc/xstartup.bak
touch /home/$USUARIO/.vnc/xstartup
echo "$xstartupConf" > /home/$USUARIO/.vnc/xstartup
touch /etc/systemd/system/vncserver@.service
echo "$unitConf" > /etc/systemd/system/vncserver@.service 
systemctl daemon-reload
systemctl enable vncserver@1.service
systemctl start vncserver@1
systemctl status vncserver@1
#==================================================================================== #
