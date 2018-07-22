# lnmp
for docker lnmp galera test. test in localhost like:
docker network create david-net
docker run -p 80:80 --name n1 --net=david-net -d novice/lnmp --wsrep-new-cluster --wsrep-cluster-address=gcomm:// 
docker run --name n2  --net=david-net -d novice/lnmp --wsrep-cluster-address=gcomm://n1
docker run --name n3  --net=david-net -d novice/lnmp --wsrep-cluster-address=gcomm://n1 

docker exec -t n1 mysql -uroot -pfreego -e 'show status like "wsrep_cluster_size"'
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
# build locally
docker build -t novice/lnmp .
# run it on several host like this
referrence and modified from:
http://galeracluster.com/2015/05/getting-started-galera-with-docker-part-2-2/
suppose following 3 nodes
n1 10.10.10.10
n2 10.10.10.11
n3 10.10.10.12
A simple cluster setup would look like this:

n1$ docker run -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 -d \
-v "$PWD/cron_task":/etc/cron.d/ \
-v /my_php_site_src_path:/var/www:rw \
-v /my/own/datadir:/var/lib/mysql  \
-e MYSQL_ROOT_PASSWORD=my-secret-pw \
-e MYSQL_USER=david -e MYSQL_PASSWORD=mypassword -e MYSQL_DATABASE=mydb \
--name n1 -t novice/lnmp \
--wsrep-new-cluster \
--wsrep-cluster-address=gcomm:// --wsrep-node-address=10.10.10.10

n2$ docker run -d -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 \
--name n2 -t novice/lnmp 
--wsrep-cluster-address=gcomm://10.10.10.10 --wsrep-node-address=10.10.10.11

n3$ docker run -d -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 \
--name n3 -t novice/lnmp 
--wsrep-cluster-address=gcomm://10.10.10.10 --wsrep-node-address=10.10.10.12

n1$ docker exec -t n1 mysql -uroot -pfreego -e 'show status like "wsrep_cluster_size"'
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size |     3 |
+--------------------+-------+

In case 3306 occupied, try this way:
n1$ docker run -d -p 40080:80 -p 40443:443 -p 43306:3306 -p 44567:44567 -p 44444:44444 -p 44568:44568 \
-v /php_src_path:/var/www:rw \
-v /data_dir:/var/lib/mysql  \
--name n1 novice/lnmp --wsrep-new-cluster --wsrep-cluster-address=gcomm:// \
--wsrep-node-address=10.10.10.10:44567 --wsrep-sst-receive-address=10.10.10.10:44444 \
--wsrep-provider-options="ist.recv_addr=10.10.10.10:44568"

n2$ docker run -d -p 40080:80 -p 40443:443  -p 43306:3306 -p 44567:44567 -p 44444:44444 -p 44568:44568 \
-v /var/www/app:/var/www:rw \
-v /var/lib/mysql:/var/lib/mysql  \
--name n2 novice/lnmp --wsrep-cluster-address=gcomm://10.10.10.10:44567 \
--wsrep-node-address=10.10.10.11:44567 --wsrep-sst-receive-address=10.10.10.11:44444 \
--wsrep-provider-options="ist.recv_addr=10.10.10.11:44568"

n3$ docker run -d -p 40080:80 -p 40443:443  -p 43306:3306 -p 44567:44567 -p 44444:44444 -p 44568:44568 \
--name n3 novice/lnmp --wsrep-cluster-address=gcomm://10.10.10.10:44567 \
--wsrep-node-address=10.10.10.12:44567 --wsrep-sst-receive-address=10.10.10.12:44444 \
--wsrep-provider-options="ist.recv_addr=10.10.10.12:44568"

