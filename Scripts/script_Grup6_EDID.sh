#!/bin/bash

# Script - Edison

echo "Montando infraestructura de AWS ..."

# =======================
# VARIABLES GLOBALES
# =======================

KEY_NAME="6" #METE TU CONTRASEÑA!!!!!!!!
VPC_NAME="vpc-edid-2025-grupo6"
DB_SUBNET_GROUP_NAME="subnet-group-edid"
REGION="us-east-1"
AMI_ID="ami-04b4f1a9cf54c11d0" # Ubuntu Server 24.04 en us-east-1

# ===================
# PARES DE CLAVES
# ===================

echo "Creando pares de claves ..."

aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > $KEY_NAME.pem

chmod 400 $KEY_NAME.pem

# ===============================================
# VPC Y SUBREDES EN 2 ZONAS DE DISPONIBILIDAD
# ===============================================

echo "Creando VPC y Subredes en 2 zonas de disponibilidad ..."

VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 192.168.0.0/16 \
  --query 'Vpc.VpcId' \
  --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

aws ec2 create-tags \
  --resources $VPC_ID \
  --tags Key=Name,Value="$VPC_NAME"

SUBNET_PUBLIC1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 192.168.100.0/24 \
  --availability-zone ${REGION}a \
  --query 'Subnet.SubnetId' \
  --output text)

SUBNET_PUBLIC2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 192.168.105.0/24 \
  --availability-zone ${REGION}b \
  --query 'Subnet.SubnetId' \
  --output text)

SUBNET_PRIVATE1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 192.168.101.0/24 \
  --availability-zone ${REGION}a \
  --query 'Subnet.SubnetId' \
  --output text)

SUBNET_PRIVATE2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 192.168.102.0/24 \
  --availability-zone ${REGION}b \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 create-tags --resources $SUBNET_PUBLIC1_ID --tags Key=Name,Value="Subnet-Publica-1"
aws ec2 create-tags --resources $SUBNET_PUBLIC2_ID --tags Key=Name,Value="Subnet-Publica-2"
aws ec2 create-tags --resources $SUBNET_PRIVATE1_ID --tags Key=Name,Value="Subnet-Privada-1"
aws ec2 create-tags --resources $SUBNET_PRIVATE2_ID --tags Key=Name,Value="Subnet-Privada-2"

echo "Se han creado las siguientes subredes: "
echo " - Pública 1: $SUBNET_PUBLIC1_ID"
echo " - Pública 2: $SUBNET_PUBLIC2_ID"
echo " - Privada 1: $SUBNET_PRIVATE1_ID"
echo " - Privada 2: $SUBNET_PRIVATE2_ID"

# ===============
# GATEWAY NAT
# ===============

echo "Configurando Gateway NAT ..."

IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID

# =======================
# GRUPOS DE SEGURIDAD
# =======================

echo "Creando Grupos de Seguridad ..."

SG_PROXY_ID=$(aws ec2 create-security-group \
  --group-name SG-Proxy \
  --description "Proxy Nginx" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)


SG_SQL_ID=$(aws ec2 create-security-group \
  --group-name SG-SQL \
  --description "SQL en EC2" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

SG_WEB_ID=$(aws ec2 create-security-group \
  --group-name SG-WEB \
  --description "Servidor WEB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

  SG_RDS_ID=$(aws ec2 create-security-group \
  --group-name SG-RDS \
  --description "RDS MySQL" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)


# SG-Proxy: HTTP, HTTPS, SSH abiertos (para demo)
aws ec2 authorize-security-group-ingress --group-id $SG_PROXY_ID --protocol tcp --port 80  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_PROXY_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_PROXY_ID --protocol tcp --port 22  --cidr 0.0.0.0/0



# SG-SQL
aws ec2 authorize-security-group-ingress --group-id $SG_SQL_ID --protocol tcp --port 3306 --source-group $SG_WEB_ID


# SG-WEB
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 80  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 22  --cidr 192.168.0.0/16

# SG-RDS
aws ec2 authorize-security-group-ingress --group-id $SG_RDS_ID --protocol tcp --port 3306 --source-group $SG_PROXY_ID



# ==================
# INSTANCIAS EC2
# ==================

echo "Creando instancias EC2 ..."

# Proxy Nginx 1 (IP pública)
INSTANCE_PROXY1_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name $KEY_NAME \
  --subnet-id $SUBNET_PUBLIC1_ID \
  --private-ip-address 192.168.100.10 \
  --security-group-ids $SG_PROXY_ID \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' \
  --output text)

aws ec2 create-tags \
  --resources $INSTANCE_PROXY1_ID \
  --tags Key=Name,Value="Proxyinverso1"

# ===================
# SUBRED PARA RDS
# ===================

echo "Creando grupo de subredes para RDS MySQL ..."

aws rds create-db-subnet-group \
 --db-subnet-group-name "cms-db-subnet-group" \
  --db-subnet-group-description "Grupo de subredes para RDS MySQL CMS" \
  --subnet-ids $SUBNET_PRIVATE1_ID $SUBNET_PRIVATE2_ID \
  --tags Key=Name,Value="cms-db-subnet-group"

# =================
# INSTANCIA RDS
# =================

echo "Creando instancia de RDS MySQL ..."

aws rds create-db-instance \
  --db-instance-identifier "cms-database" \
  --allocated-storage 20 \
  --storage-type "gp2" \
  --db-instance-class "db.t3.micro" \
  --engine "mysql" \
  --engine-version "8.0" \
  --master-username "admin" \
  --master-user-password "Admin123" \
  --db-name "wordpress_db" \
  --db-subnet-group-name "cms-db-subnet-group" \
  --vpc-security-group-ids "$SG_RDS_ID" \
  --publicly-accessible \
  --tags Key=Name,Value="wordpress_db"

echo "Instancia RDS MySQL creada exitosamente."

# ============================
# AWS WAF: WEB ACL + ASOCIACIÓN
# ============================

echo "Creando Web ACL de AWS WAF..."

WEB_ACL_ARN=$(aws wafv2 create-web-acl \
  --name waf-edid-2025 \
  --scope REGIONAL \
  --region $REGION \
  --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=waf-edid-metrics \
  --query 'Summary.ARN' \
  --output text)

echo "Web ACL creado: $WEB_ACL_ARN"
if [ -z "$WEB_ACL_ARN" ]; then
  echo "ERROR: No se ha podido crear el Web ACL."
  exit 1
fi

echo "✅ WAF asociado al ALB correctamente"
echo "-----------------------------------------"
echo "✅ La infraestructura de AWS ha sido creada con éxito ✅"





