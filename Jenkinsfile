pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
    }

    stages {
        stage('User Selections') {
            steps {
                script {
                    def testChoice = input(
                        id: 'testChoice',
                        message: 'Select testing tools to run',
                        parameters: [
                            choice(name: 'TEST_TOOLS', choices: ['none', 'junit', 'keploy', 'both'], description: 'Choose test tools')
                        ]
                    )
                    env.TEST_TOOLS = testChoice

                    def scanChoice = input(
                        id: 'scanChoice',
                        message: 'Select security tools to run',
                        parameters: [
                            choice(name: 'SECURITY_TOOLS', choices: ['none', 'gitleaks', 'snyk', 'both'], description: 'Choose security tools')
                        ]
                    )
                    env.SECURITY_TOOLS = scanChoice

                    def deployChoice = input(
                        id: 'deployChoice',
                        message: 'Select deployment/analysis tools to run',
                        parameters: [
                            choice(name: 'DEPLOY_TOOLS', choices: ['none', 'sonarqube', 'jfrog', 'both'], description: 'Choose tools')
                        ]
                    )
                    env.DEPLOY_TOOLS = deployChoice
                }
            }
        }

        stage('Build & Unit Test') {
            when {
                expression { env.TEST_TOOLS == 'junit' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Running Maven build and unit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Install Keploy') {
            when {
                expression { env.TEST_TOOLS == 'keploy' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Installing Keploy...'
                sh '''
                    curl --silent -O -L https://keploy.io/install.sh
                    chmod +x install.sh
                    bash install.sh
                    sudo mv keploy /usr/local/bin/keploy || true
                    sudo chmod +x /usr/local/bin/keploy
                '''
            }
        }

        stage('Run Keploy Tests') {
            when {
                expression { env.TEST_TOOLS == 'keploy' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Running Keploy tests...'
                sh 'sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI'
            }
        }

        stage('Run Gitleaks Scan') {
            when {
                expression { env.SECURITY_TOOLS == 'gitleaks' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Gitleaks scan...'
                sh '''
                    docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect \
                        --source=/path \
                        --report-format=json \
                        --report-path=/path/gitleaks-report.json || echo "Gitleaks completed with findings"
                '''
                echo 'Review gitleaks-report.json for results.'
            }
        }

        stage('Run Snyk Analysis') {
            when {
                expression { env.SECURITY_TOOLS == 'snyk' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Snyk analysis (placeholder)...'
                sh 'echo "Snyk analysis executed."'
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { env.DEPLOY_TOOLS == 'sonarqube' || env.DEPLOY_TOOLS == 'both' }
            }
            steps {
                echo 'Running SonarQube scan...'
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=junit-jenkins-demo \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                        -Dsonar.surefire.reportsPath=target/surefire-reports \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.tests=src/test/java \
                        -Dsonar.java.test.binaries=target/test-classes
                    '''
                }
            }
        }

        stage('Upload to JFrog Artifactory') {
            when {
                expression { env.DEPLOY_TOOLS == 'jfrog' || env.DEPLOY_TOOLS == 'both' }
            }
            steps {
                echo 'Uploading artifact to JFrog...'
                script {
                    def server = Artifactory.server 'my-artifactory'
                    def buildInfo = Artifactory.newBuildInfo()
                    def uploadSpec = """{
                        "files": [{
                            "pattern": "target/*.jar",
                            "target": "libs-release-local/"
                        }]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo "✅ Build succeeded with:\nTest Tools: ${env.TEST_TOOLS}\nSecurity Tools: ${env.SECURITY_TOOLS}\nDeploy Tools: ${env.DEPLOY_TOOLS}"
        }
        failure {
            echo "❌ Pipeline failed. Check logs above for errors."
        }
    }
}
