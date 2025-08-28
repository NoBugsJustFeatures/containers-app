pipeline {
  agent any

  environment {
    REGISTRY       = "docker.io"
    DOCKERHUB_REPO = "your-dockerhub-username/yourapp"  // <== đổi tên repo của bạn
    IMAGE          = "${DOCKERHUB_REPO}"
    DOCKER_CREDS   = "dockerhub"                         // Jenkins credentials id
    SSH_CREDS      = "deploy-ssh"                        // Jenkins credentials id
    DEPLOY_USER    = "ubuntu"                            // <== user trên server
    DEPLOY_HOST    = "123.45.67.89"                      // <== IP/host server
    DEPLOY_DIR     = "/opt/myapp"
    COMPOSE_FILE   = "docker-compose.prod.yml"
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  triggers {
    // Với GitHub: bật webhook "push" + cài GitHub plugin => kích hoạt tự động.
    // Nếu không dùng webhook, có thể mở Poll SCM: pollSCM('H/2 * * * *')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.GIT_SHORT = sh(script: "git rev-parse --short=7 HEAD", returnStdout: true).trim()
          env.BRANCH = env.BRANCH_NAME ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
        }
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          set -e
          if [ -f package.json ]; then
            npm ci
            npm test
          elif [ -f composer.json ]; then
            composer install --no-interaction --prefer-dist
            ./vendor/bin/phpunit || ./vendor/bin/pest || true
          elif [ -f pom.xml ]; then
            mvn -B -DskipTests=false test
          else
            echo "No test step configured for this project. Skipping."
          fi
        '''
      }
    }

    stage('Build Docker image') {
      steps {
        sh """
          docker build -t ${IMAGE}:${GIT_SHORT} -t ${IMAGE}:${BRANCH} -t ${IMAGE}:latest .
        """
      }
    }

    stage('Push Docker image') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh """
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin ${REGISTRY}
            docker push ${IMAGE}:${GIT_SHORT}
            docker push ${IMAGE}:${BRANCH}
            docker push ${IMAGE}:latest
            docker logout ${REGISTRY} || true
          """
        }
      }
    }

    stage('Deploy to Server (main only)') {
      when { branch 'main' }
      steps {
        sshagent (credentials: ["${SSH_CREDS}"]) {
          sh """
            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
              set -e
              mkdir -p ${DEPLOY_DIR}
              cd ${DEPLOY_DIR}

              # Cập nhật file .env để compose lấy đúng image:tag
              echo "IMAGE=${IMAGE}" > .env
              echo "TAG=${GIT_SHORT}" >> .env

              # Tải compose file mới nhất từ repo (lần đầu có thể scp từ Jenkins)
              if [ ! -f ${COMPOSE_FILE} ]; then
                echo "${COMPOSE_FILE} missing. Creating a minimal one..."
                cat > ${COMPOSE_FILE} <<EOF
services:
  web:
    image: \\${IMAGE}:\\${TAG}
    ports:
      - "80:8080"
    restart: unless-stopped
EOF
              fi

              # Pull & chạy
              docker compose --env-file .env -f ${COMPOSE_FILE} pull
              docker compose --env-file .env -f ${COMPOSE_FILE} up -d
              docker image prune -f
            '
          """
        }
      }
    }
  }

  post {
    always {
      junit allowEmptyResults: true, testResults: '**/junit*.xml,**/test-results/**/*.xml'
      cleanWs()
    }
  }
}
