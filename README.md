# kube_tensorflow_on_edge
This is a repository for lab use, which create a kubernetes platform to incorporate tensorflow on the edge devices.

The usage of bash script files:

kube-start-up.sh: To initial the variables of system, and start up kubernetes. 
kube-create-po.sh: To create pods on each tensorflow nodes, to download needed tensorflow app files, and to execute the apps for model training on the pods.
pod-sources-download.sh: To download the tensorflow app files from github, and extract them on each pod.
getPod.gawk: A gawk script to parse the pod name from the "pod:IP:status" information. It could be used to parse IP or status, with no amendment but adjust the input ${n}.
