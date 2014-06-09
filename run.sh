CURR_DIR=$(cd ${0%/*} && pwd)

cd mapreduce/
mvn exec:java -Dexec.mainClass="pl.edu.agh.student.offlinedstream.OffDstream" -Dexec.args=$CURR_DIR"/input "$CURR_DIR"/pipe 5 1000"

cd ../clusterisation
mvn exec:java -Dexec.mainClass="pl.edu.agh.student.clusterisation.Main"