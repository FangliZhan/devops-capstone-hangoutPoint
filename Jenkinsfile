node {
	def application = "nginxapp"
	def dockerhubaccountid = "fanglizhan1028"
	stage('Clone repository') {
		checkout scm
	}

	stage('Build image') {
		app = docker.build("${dockerhubaccountid}/${application}:${BUILD_NUMBER}")
	}

	stage('Push image') {
		withDockerRegistry([ credentialsId: "dockerHub", url: "" ]) {
		app.push()
		app.push("latest")
	}
	}

	stage('Deploy') {
		sh ("docker run -d -p 82:80 ${dockerhubaccountid}/${application}:${BUILD_NUMBER}")
	}
	
	stage('Remove the container after deployment') {
		// remove docker container
		// sh ("docker ps -f name=${dockerhubaccountid}/${application}:${BUILD_NUMBER} | xargs --no-run-if-empty docker container stop")
		sh ("timeout 30 docker ps -aq | xargs -r docker rm -f || true")
   	 }
	
	stage('Remove old images') {
		// remove docker pld images
		sh("docker rmi ${dockerhubaccountid}/${application}:latest -f")
   	}
}
