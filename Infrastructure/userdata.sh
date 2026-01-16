#!/bin/bash
SECONDS=0
exec > /var/log/user-data.log 2>&1
echo "--- Start Startup Skript: $(date) ---"

# 1. INSTALLATION
dnf update -y
dnf install -y docker git python3 postgresql17 nmap-ncat
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 2. PROJECT & ENV
cd /home/ec2-user
git clone https://github.com/marcel-erbas/AWS_grocery.git
cd AWS_grocery/backend

JWT_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')

cat <<EOT > .env
JWT_SECRET_KEY=$JWT_SECRET
POSTGRES_USER=${grocery_username}
POSTGRES_PASSWORD=${grocery_user_db_password}
POSTGRES_DB=${grocery_db_name}
POSTGRES_HOST=${rds_endpoint}
POSTGRES_URI=postgresql://${grocery_username}:${grocery_user_db_password}@${rds_endpoint}:5432/${grocery_db_name}

# S3 configuration
S3_BUCKET_NAME=${s3_bucket_name}
S3_REGION=${aws_region}
USE_S3_STORAGE=true
EOT

# 3. Wait for RDS to be available
echo "Wait for RDS..."
until nc -zv ${rds_endpoint} 5432; do
  echo "Wait for RDS connection..."
  sleep 5
done

# 4. Database setup (user & schema)
export PGPASSWORD='${rds_master_password}'

echo "Set up SQL users and permissions..."
psql -h ${rds_endpoint} -U postgres -d ${grocery_db_name} <<EOF
-- Create a user if one does not already exist
DO \$\$ 
BEGIN 
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'grocery_user') THEN 
    CREATE USER grocery_user WITH ENCRYPTED PASSWORD '${grocery_user_db_password}'; 
  END IF; 
END \$\$;

-- Berechtigungen am Schema public vergeben
GRANT ALL ON SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO grocery_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO grocery_user;

-- Da RDS kein echtes SUPERUSER erlaubt, geben wir die rds_superuser Rolle
GRANT rds_superuser TO grocery_user;
EOF

# Schema import with the shop user
export PGPASSWORD='${grocery_user_db_password}'
echo "Starte Import..."
psql -h ${rds_endpoint} -U ${grocery_username} -d ${grocery_db_name} -f /home/ec2-user/AWS_grocery/backend/app/sqlite_dump_clean.sql

# 5. DOCKER BUILD & RUN 
echo "Baue und starte App..."
docker build -t grocerymate .
docker run -d --network host \
  --name grocery-app \
  --restart always \
  -e S3_BUCKET_NAME=${s3_bucket_name} \
  -e S3_REGION=${aws_region} \
  -e USE_S3_STORAGE=true \
  -e POSTGRES_USER=${grocery_username} \
  -e POSTGRES_PASSWORD=${grocery_user_db_password} \
  -e POSTGRES_DB=${grocery_db_name} \
  -e POSTGRES_HOST=${rds_endpoint} \
  grocerymate

# 6. FINISH
chown -R ec2-user:ec2-user /home/ec2-user/AWS_grocery
echo "--- Startup script finished: $(date) ---"
echo "Script execution completed in $SECONDS seconds."