pipeline {
    agent any

    environment {
        RUN_JUNIT = 'false'
        RUN_KEPLOY = 'false'
    }

    stages {
        stage('Select Test Type') {
            steps {
                script {
                    def choice = input message: 'Which tests would you like to run?', parameters: [
                        choice(name: 'TEST_TYPE', choices: ['junit', 'keploy', 'both'], description: 'Select test type')
                    ]

                    if (choice == 'junit') {
                        env.RUN_JUNIT = 'true'
                    } else if (choice == 'keploy') {
                        env.RUN_KEPLOY = 'true'
                    } else if (choice == 'both') {
                        env.RUN_JUNIT = 'true'
                        env.RUN_KEPLOY = 'true'
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
                expression { env.RUN_JUNIT == 'true' }
            }
            steps {
                echo "Running JUnit tests..."
                sh 'mvn test'
            }
        }

        stage('Keploy Test') {
            when {
                expression { env.RUN_KEPLOY == 'true' }
            }
            steps {
                echo "Running Keploy tests with Docker..."
                sh '''
                    docker run --rm \
                        -v "$(pwd)":/app \
                        -w /app \
                        keploy/keploy:latest test -c "java -cp target/classes com.example.StringUtils"
                '''
            }
        }

        stage('Archive JUnit Results') {
            when {
                expression { env.RUN_JUNIT == 'true' }
            }
            steps {
                echo "Archiving JUnit results..."
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Archive Keploy Results') {
            when {
                expression { env.RUN_KEPLOY == 'true' }
            }
            steps {
                echo "Archiving Keploy results..."
                archiveArtifacts artifacts: 'keploy/reports/**', allowEmptyArchive: true
            }
        }
    }
}
