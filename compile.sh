RUNNER_SCRIPT_DIR=$(cd ${0%/*} && pwd)

cd $RUNNER_SCRIPT_DIR/clusterisation
mvn install
cd $RUNNER_SCRIPT_DIR/mapreduce
mvn install