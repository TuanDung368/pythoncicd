pipeline {
    agent any // Hoặc chỉ định một agent cụ thể có Docker

    environment {
        // Thay đổi các biến này cho phù hợp với repo và Docker Hub của bạn
        GITHUB_REPO_URL = 'https://github.com/TuanDung368/flask-docker-app.git' // Thay đổi thành repo của bạn
        GITHUB_BRANCH   = 'main' // Nhánh chính của bạn

        DOCKER_IMAGE_NAME = 'your-dockerhub-username/flask-docker-app' // Thay đổi thành username Docker Hub của bạn
        DOCKER_IMAGE_TAG  = "${env.BUILD_NUMBER}" // Sử dụng số build của Jenkins làm tag
        DOCKER_CREDENTIAL_ID = 'your-dockerhub-credential-id' // ID của credential Docker Hub trong Jenkins
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo "Cloning repository: ${env.GITHUB_REPO_URL} on branch: ${env.GITHUB_BRANCH}"
                git branch: env.GITHUB_BRANCH, url: env.GITHUB_REPO_URL
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                script {
                    // Đảm bảo Docker có sẵn trên Jenkins agent
                    def dockerExists = sh(script: 'command -v docker', returnStatus: true) == 0
                    if (!dockerExists) {
                        error "Docker command not found on agent. Please ensure Docker is installed and in PATH."
                    }
                    sh "docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ."
                    echo "Docker image built successfully."
                }
            }
        }

        stage('Run Tests in Docker') {
            steps {
                echo "Running tests using the built Docker image..."
                script {
                    def dockerExists = sh(script: 'command -v docker', returnStatus: true) == 0
                    if (!dockerExists) {
                        error "Docker command not found. Cannot run tests in Docker."
                    }

                    // Chạy test trong một container tạm thời từ image vừa build
                    // Giả định bạn có pytest và các test trong thư mục 'tests'
                    // Lệnh này sẽ tạm thời override CMD trong Dockerfile để chạy pytest
                    // Cần đảm bảo pytest được cài đặt trong Dockerfile hoặc môi trường test
                    echo "Attempting to run tests with 'pytest' inside container..."
                    try {
                        sh "docker run --rm ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} python -m pytest tests/"
                        echo "Tests passed successfully!"
                    } catch (Exception e) {
                        error "Tests failed! Check console output for details.\n${e.getMessage()}"
                    }
                }
            }
        }

        stage('Push Docker Image to Registry') {
            steps {
                echo "Pushing Docker image to Docker Hub: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                script {
                    def dockerExists = sh(script: 'command -v docker', returnStatus: true) == 0
                    if (!dockerExists) {
                        error "Docker command not found. Cannot push Docker image."
                    }

                    // Sử dụng credential để đăng nhập Docker Hub
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIAL_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                        echo "Docker image pushed successfully."
                    }
                }
            }
        }

        // Stage "Deploy" thực sự sẽ phụ thuộc vào môi trường của bạn
        // Đây là ví dụ cho việc triển khai lên một máy chủ bằng SSH
        stage('Deploy to Server') {
            steps {
                echo "Deploying application to production server..."
                // Thay đổi các giá trị này cho phù hợp với server của bạn
                def SERVER_USER = 'jenkins'
                def SERVER_HOST = 'your-production-server-ip-or-hostname'
                def DEPLOY_PATH = '/opt/flask-app' // Đường dẫn trên server để triển khai ứng dụng
                def SSH_CREDENTIAL_ID = 'your-ssh-credential-id' // ID của SSH credential trong Jenkins

                // Ví dụ triển khai bằng SSH:
                // Bước 1: SSH vào server
                // Bước 2: Dừng container cũ (nếu có)
                // Bước 3: Kéo image mới nhất từ Docker Hub
                // Bước 4: Chạy container mới
                withCredentials([sshUserPrivateKey(credentialsId: SSH_CREDENTIAL_ID, keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_HOST} <<EOF
                        echo "Logged into ${SERVER_HOST}"
                        # Dừng và xóa container cũ nếu đang chạy
                        if docker ps -a --format '{{.Names}}' | grep -q 'flask-app-container'; then
                            echo "Stopping existing container..."
                            docker stop flask-app-container || true
                            docker rm flask-app-container || true
                        fi
                        echo "Pulling latest image: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                        docker pull ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                        echo "Running new container..."
                        docker run -d --name flask-app-container -p 80:5000 ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                        echo "Deployment complete on ${SERVER_HOST}"
                        EOF
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Luôn dọn dẹp không gian làm việc
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
