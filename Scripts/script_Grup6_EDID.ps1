Param(
    [string]$KeyName = "natali",
    [string]$VpcName = "vpc-edid-2025-grupo6",
    [string]$DbSubnetGroupName = "subnet-group-edid",
    [string]$Region = "us-east-1",
    [string]$AmiId = "ami-04b4f1a9cf54c11d0" # Ubuntu Server 24.04 en us-east-1
)

$ErrorActionPreference = "Stop"

Write-Host "Montando infraestructura de AWS ..."

# =======================
# PARES DE CLAVES
# =======================

Write-Host "Creando pares de claves ..."

$keyMaterial = aws ec2 create-key-pair `
    --key-name $KeyName `
    --query 'KeyMaterial' `
    --output text

$keyPath = "$KeyName.pem"
$keyMaterial | Out-File -FilePath $keyPath -Encoding ascii -Force
icacls $keyPath /inheritance:r | Out-Null
icacls $keyPath /grant:r "$($env:USERNAME):(R)" | Out-Null

# ===============================================
# VPC Y SUBREDES EN 2 ZONAS DE DISPONIBILIDAD
# ===============================================

Write-Host "Creando VPC y Subredes en 2 zonas de disponibilidad ..."

$VPC_ID = aws ec2 create-vpc `
    --cidr-block 192.168.0.0/16 `
    --query 'Vpc.VpcId' `
    --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support | Out-Null
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames | Out-Null

aws ec2 create-tags `
  --resources $VPC_ID `
  --tags Key=Name,Value="$VpcName" | Out-Null

$SUBNET_PUBLIC1_ID = aws ec2 create-subnet `
  --vpc-id $VPC_ID `
  --cidr-block 192.168.100.0/24 `
  --availability-zone "${Region}a" `
  --query 'Subnet.SubnetId' `
  --output text

$SUBNET_PUBLIC2_ID = aws ec2 create-subnet `
  --vpc-id $VPC_ID `
  --cidr-block 192.168.105.0/24 `
  --availability-zone "${Region}b" `
  --query 'Subnet.SubnetId' `
  --output text

$SUBNET_PRIVATE1_ID = aws ec2 create-subnet `
  --vpc-id $VPC_ID `
  --cidr-block 192.168.101.0/24 `
  --availability-zone "${Region}a" `
  --query 'Subnet.SubnetId' `
  --output text

$SUBNET_PRIVATE2_ID = aws ec2 create-subnet `
  --vpc-id $VPC_ID `
  --cidr-block 192.168.102.0/24 `
  --availability-zone "${Region}b" `
  --query 'Subnet.SubnetId' `
  --output text

aws ec2 create-tags --resources $SUBNET_PUBLIC1_ID  --tags Key=Name,Value="Subnet-Publica-1"  | Out-Null
aws ec2 create-tags --resources $SUBNET_PUBLIC2_ID  --tags Key=Name,Value="Subnet-Publica-2"  | Out-Null
aws ec2 create-tags --resources $SUBNET_PRIVATE1_ID --tags Key=Name,Value="Subnet-Privada-1" | Out-Null
aws ec2 create-tags --resources $SUBNET_PRIVATE2_ID --tags Key=Name,Value="Subnet-Privada-2" | Out-Null

Write-Host "Se han creado las siguientes subredes: "
Write-Host " - Pública 1: $SUBNET_PUBLIC1_ID"
Write-Host " - Pública 2: $SUBNET_PUBLIC2_ID"
Write-Host " - Privada 1: $SUBNET_PRIVATE1_ID"
Write-Host " - Privada 2: $SUBNET_PRIVATE2_ID"

# ===============
# GATEWAY NAT
# ===============

Write-Host "Configurando Gateway NAT ..."

$IGW_ID = aws ec2 create-internet-gateway `
  --query 'InternetGateway.InternetGatewayId' `
  --output text

aws ec2 attach-internet-gateway `
  --vpc-id $VPC_ID `
  --internet-gateway-id $IGW_ID | Out-Null

# =======================
# GRUPOS DE SEGURIDAD
# =======================

Write-Host "Creando Grupos de Seguridad ..."

$SG_PROXY_ID = aws ec2 create-security-group `
  --group-name SG-Proxy `
  --description "Proxy Nginx" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

$SG_SQL_ID = aws ec2 create-security-group `
  --group-name SG-SQL `
  --description "SQL en EC2" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

$SG_WEB_ID = aws ec2 create-security-group `
  --group-name SG-WEB `
  --description "Servidor WEB" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

$SG_RDS_ID = aws ec2 create-security-group `
  --group-name SG-RDS `
  --description "RDS MySQL" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

# SG-Proxy: HTTP, HTTPS, SSH abiertos (para demo)
aws ec2 authorize-security-group-ingress --group-id $SG_PROXY_ID --protocol tcp --port 80  --cidr 0.0.0.0/0  | Out-Null
aws ec2 authorize-security-group-ingress --group-id $SG_PROXY_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 | Out-Null
aws ec2 authorize-security-group-ingress --group-id $SG_PROXY_ID --protocol tcp --port 22  --cidr 0.0.0.0/0  | Out-Null

# SG-SQL
aws ec2 authorize-security-group-ingress --group-id $SG_SQL_ID --protocol tcp --port 3306 --source-group $SG_WEB_ID | Out-Null

# SG-WEB
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 80  --cidr 0.0.0.0/0  | Out-Null
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 | Out-Null
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 22  --cidr 192.168.0.0/16 | Out-Null

# SG-RDS
aws ec2 authorize-security-group-ingress --group-id $SG_RDS_ID --protocol tcp --port 3306 --source-group $SG_PROXY_ID | Out-Null

# ==================
# INSTANCIAS EC2
# ==================

Write-Host "Creando instancias EC2 ..."

$INSTANCE_PROXY1_ID = aws ec2 run-instances `
  --image-id $AmiId `
  --instance-type t2.micro `
  --key-name $KeyName `
  --subnet-id $SUBNET_PUBLIC1_ID `
  --private-ip-address 192.168.100.10 `
  --security-group-ids $SG_PROXY_ID `
  --associate-public-ip-address `
  --query 'Instances[0].InstanceId' `
  --output text

aws ec2 create-tags `
  --resources $INSTANCE_PROXY1_ID `
  --tags Key=Name,Value="Proxyinverso1" | Out-Null

# ===================
# SUBRED PARA RDS
# ===================

Write-Host "Creando grupo de subredes para RDS MySQL ..."

aws rds create-db-subnet-group `
  --db-subnet-group-name "cms-db-subnet-group" `
  --db-subnet-group-description "Grupo de subredes para RDS MySQL CMS" `
  --subnet-ids $SUBNET_PRIVATE1_ID $SUBNET_PRIVATE2_ID `
  --tags Key=Name,Value="cms-db-subnet-group" | Out-Null

# =================
# INSTANCIA RDS
# =================

Write-Host "Creando instancia de RDS MySQL ..."

aws rds create-db-instance `
  --db-instance-identifier "cms-database" `
  --allocated-storage 20 `
  --storage-type "gp2" `
  --db-instance-class "db.t3.micro" `
  --engine "mysql" `
  --engine-version "8.0" `
  --master-username "admin" `
  --master-user-password "Admin123" `
  --db-name "wordpress_db" `
  --db-subnet-group-name "cms-db-subnet-group" `
  --vpc-security-group-ids "$SG_RDS_ID" `
  --publicly-accessible `
  --tags Key=Name,Value="wordpress_db" | Out-Null

Write-Host "Instancia RDS MySQL creada exitosamente."

# ============================
# AWS WAF: WEB ACL + REGLAS
# ============================

Write-Host "Creando Web ACL de AWS WAF..."

$wafRulesJson = @'
[
  {
    "Name": "RateLimit",
    "Priority": 0,
    "Statement": {
      "RateBasedStatement": {
        "Limit": 2000,
        "AggregateKeyType": "IP"
      }
    },
    "Action": { "Block": {} },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "RateLimit"
    }
  },
  {
    "Name": "AWSManagedRulesCommonRuleSet",
    "Priority": 1,
    "OverrideAction": { "None": {} },
    "Statement": {
      "ManagedRuleGroupStatement": {
        "VendorName": "AWS",
        "Name": "AWSManagedRulesCommonRuleSet"
      }
    },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "AWSManagedRulesCommonRuleSet"
    }
  },
  {
    "Name": "AWSManagedRulesSQLiRuleSet",
    "Priority": 2,
    "OverrideAction": { "None": {} },
    "Statement": {
      "ManagedRuleGroupStatement": {
        "VendorName": "AWS",
        "Name": "AWSManagedRulesSQLiRuleSet"
      }
    },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "AWSManagedRulesSQLiRuleSet"
    }
  },
  {
    "Name": "BlockBadBotsUserAgent",
    "Priority": 3,
    "Statement": {
      "ByteMatchStatement": {
        "FieldToMatch": {
          "SingleHeader": { "Name": "user-agent" }
        },
        "PositionalConstraint": "CONTAINS",
        "SearchString": "BadBot",
        "TextTransformations": [
          {
            "Priority": 0,
            "Type": "NONE"
          }
        ]
      }
    },
    "Action": { "Block": {} },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "BlockBadBotsUserAgent"
    }
  }
]
'@

$rulesFile = "waf-rules.json"
$wafRulesJson | Out-File -FilePath $rulesFile -Encoding utf8 -Force

$WEB_ACL_ARN = aws wafv2 create-web-acl `
  --name waf-edid-2025 `
  --scope REGIONAL `
  --region $Region `
  --default-action Allow={} `
  --rules "file://$rulesFile" `
  --visibility-config "SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=waf-edid-metrics" `
  --query 'Summary.ARN' `
  --output text

Write-Host "Web ACL creado: $WEB_ACL_ARN"
if ([string]::IsNullOrWhiteSpace($WEB_ACL_ARN)) {
    Write-Error "ERROR: No se ha podido crear el Web ACL."
    exit 1
}

Write-Host "WAF creado (asociación al ALB pendiente según tu entorno)."
Write-Host "-----------------------------------------"
Write-Host "La infraestructura de AWS ha sido creada con éxito."
