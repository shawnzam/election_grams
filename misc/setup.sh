echo "\"UPDATE mysql.user SET Password=PASSWORD(\"\!QAZ2wsx\") WHERE User=\"root\"; FLUSH PRIVILEGES;\"" > mysql-init
sudo /opt/bitnami/ctlscript.sh stop mysql
sudo /opt/bitnami/mysql/bin/mysqld_safe --defaults-file=/opt/bitnami/mysql/my.cnf --pid-file=/opt/bitnami/mysql/data/mysqld.pid --init-file=/home/bitnami/mysql-init 2> /dev/null &
sudo /opt/bitnami/ctlscript.sh restart mysql
rm /home/bitnami/mysql-init
sudo gem upgrade activerecord
sudo gem install stemmify