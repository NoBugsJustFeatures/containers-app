pipeline {
    agent { label "${params.Server}" }

    environment {
        GIT_REPO     = 'https://github.com/NoBugsJustFeatures/containers-app.git'
        GIT_CRED     = 'jenkins-github-pat'
        COMPOSE_FILE = 'docker-compose.yml'
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    parameters {
        choice(name: 'Server', choices: ['192.168.1.4'], description: 'Node to run on')
        choice(name: 'Action', choices: ['Deploy','Backup','Rollback','Stop','Restart','Update'], description: 'Action to perform')
        string(name: 'Rollback_version', defaultValue: '', description: 'Rollback archive file if needed')
        string(name: 'Branch', defaultValue: 'main', description: 'Git branch or commit hash')
    }

    stages {

        stage('Provide access') {
            steps {
                script {
                    sh '''
                        sudo chown -R vu:vu "${WORKSPACE}" || true
                        sudo chmod -R 775 "${WORKSPACE}" || true
                        sudo find "${WORKSPACE}" -type f -exec chattr -i {} + || true
                        sudo find "${WORKSPACE}" -type d -exec chattr -i {} + || true
                    '''
                }
            }
        }

        stage('Git Checkout') {
            steps {
                dir("${WORKSPACE}") {
                    script {
                        if (!fileExists("${WORKSPACE}/.git")) {
                            echo "Workspace empty, cloning repository..."
                            deleteDir()
                            sh "git clone -b ${params.Branch} ${GIT_REPO} ."
                        } else {
                            echo "Repository exists, fetching latest..."
                            sh """
                                git fetch origin ${params.Branch}
                                git reset --hard origin/${params.Branch}
                            """
                        }
                    }
                }
            }
        }

        stage('Build & Test') {
            steps {
                dir("${WORKSPACE}") {
                    echo "Building Docker images and running tests"
                    sh """
                        docker compose -f ${COMPOSE_FILE} build
                        docker compose -f ${COMPOSE_FILE} up -d
                    """
                }
            }
        }

        stage('Backup') {
            when { expression { params.Action == 'Backup' } }
            steps {
                dir("${WORKSPACE}") {
                    script {
                        env.TIMESTAMP = sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim()
                        env.BACKUP_DIR = "${WORKSPACE}/backups"
                        sh """
                            mkdir -p ${BACKUP_DIR}
                            tar -czvf ${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz .
                            # Keep only latest 3 backups
                            ls -1t ${BACKUP_DIR} | tail -n +4 | xargs -I {} rm -f ${BACKUP_DIR}/{}
                        """
                    }
                }
            }
        }

        stage('Rollback') {
            when { expression { params.Action == 'Rollback' && params.Rollback_version != '' } }
            steps {
                dir("${WORKSPACE}") {
                    echo "Rolling back from archive: ${params.Rollback_version}"
                    sh """
                        tar -xzvf ${WORKSPACE}/backups/${params.Rollback_version} -C ${WORKSPACE}
                        docker compose -f ${COMPOSE_FILE} up -d --build
                    """
                }
            }
        }

        stage('Stop') {
            when { expression { params.Action == 'Stop' } }
            steps {
                dir("${WORKSPACE}") {
                    echo "Stopping Docker Compose services"
                    sh "docker compose down --remove-orphans -v"
                }
            }
        }

        stage('Restart') {
            when { expression { params.Action == 'Restart' } }
            steps {
                dir("${WORKSPACE}") {
                    echo "Restarting Docker Compose services"
                    sh """
                        docker compose -f ${COMPOSE_FILE} down
                        docker compose -f ${COMPOSE_FILE} up -d
                    """
                }
            }
        }

    }

    post {
        always {
            echo "Workspace cleaned."
        }
    }
}
