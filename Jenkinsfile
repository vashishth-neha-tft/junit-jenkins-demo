def runJunit = false
def runKeploy = false

pipeline {
    agent any

    stages {
        stage('Select Test Type') {
            steps {
                script {
                    def choice = input message: 'Which tests would you like to run?', parameters: [
                        choice(name: 'TEST_TYPE', choices: ['junit', 'keploy', 'both'], description: 'Select test type')
                    ]

                    if (choice == 'junit') {
                        runJunit = true
                    } else if (choice == 'keploy') {
                        runKeploy = true
                    } else if (choice == 'both') {
                        runJunit = true
                        runKeploy = true
                    }
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('JUnit Test') {
            when {
                expression { return runJunit }
            }
            steps {
                echo "Running JUnit tests..."
                sh 'mvn test'
            }
        }

        stage('Keploy Test') {
            when {
                expression { return runKeploy }
            }
            steps {
                echo "Running Keploy tests with Docker..."
                sh '''
                    docker run --rm \
                        -v "$(pwd)":/app \
                        -w /app \
                        keploy/keploy-go test -c "java -cp target/classes com.example.StringUtils"
                '''
            }
        }

        stage('Archive JUnit Results') {
            when {
                expression { return runJunit }
            }
            steps {
                echo "Archiving JUnit results..."
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Archive Keploy Results') {
            when {
                expression { return runKeploy }
            }
            steps {
                echo "Archiving Keploy results..."
                archiveArtifacts artifacts: 'keploy/reports/**', allowEmptyArchive: true
            }
        }
    }
}
