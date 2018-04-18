
cd /tensorflow/distributed/
nohup python classifier.py \
 --ps_hosts=$ps_IPs \
 --worker_hosts=$worker_IPs \
 --job_name=ps \
 --task_index=$job_index >log1 &
