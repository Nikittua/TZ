
# GitLab CI/CD Pipeline with Docker and Telegram Integration

This guide provides step-by-step instructions to set up a GitLab instance with CI/CD pipeline, Docker integration, and Telegram notifications.

## Prerequisites
- Ubuntu server (recommended 22.04 LTS)
- sudo privileges
- Basic terminal knowledge

---

## 🐳 Docker Installation

1. Update system packages and install dependencies:
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl -y


2. Add Docker's official GPG key:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

3. Add Docker repository:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

4. Install Docker components:
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

---

## 🦊 GitLab Setup

1. Clone the repository:
```bash
git clone https://github.com/Nikittua/TZ.git
cd TZ
```

2. Configure Docker Compose:
```bash
vi docker-compose.yml
```
Replace these values:
- `external_url: 'http://<YOUR_SERVER_IP>:8929'`
- `GITLAB_ROOT_PASSWORD: SecurePassword123!`

3. Start containers:
```bash
docker compose up -d
```
**Wait 5-7 minutes** for initialization

4. Access GitLab at: `http://<YOUR_SERVER_IP>:8929`
   - Login: `root`
   - Password: `SecurePassword123!`

---

## 🤖 GitLab Runner Registration

1. Get registration token:
   - Go to: Admin -> CI/CD -> Runners
   - Click "New instance runner"
   - Add tags: `devops-test`
   - Copy provided token

2. Register runner:
```bash
docker exec -it runner gitlab-runner register \
  --non-interactive \
  --url 'http://<YOUR_SERVER_IP>:8929' \
  --registration-token "<YOUR_TOKEN>" \
  --executor "docker" \
  --docker-image python:3.12-alpine \
  --tag-list "devops-test" \
  --description "Fixed Runner"
```

---

## 🔧 CI/CD Configuration

1. Create .gitignore:
```bash
echo "docker-compose.yml" > .gitignore
```

2. Create `.gitlab-ci.yml` with:
```yaml
stages:
  - build
  - lint
  - test
  - notify

variables:
  PIP_CACHE_DIR: "${CI_PROJECT_DIR}/.cache/pip"
  FLAKE8_ARGS: "--max-line-length=120 --exclude=venv,__pycache__"

cache:
  paths:
    - .cache/pip/

build:
  stage: build
  tags:
    - devops-test
  image: python:3.12-alpine
  script:
    - pip install --cache-dir ${PIP_CACHE_DIR} -r requirements.txt

lint:
  stage: lint
  tags:
    - devops-test
  image: python:3.12-alpine
  script:
    - pip install --cache-dir ${PIP_CACHE_DIR} -r requirements.txt
    - flake8 ${FLAKE8_ARGS} app/
  allow_failure: false 

test:
  stage: test
  tags:
    - devops-test
  image: python:3.12-alpine
  script:
    - pip install --cache-dir ${PIP_CACHE_DIR} -r requirements.txt
    - pytest app/tests/ -v

notify_success:
  stage: notify
  tags:
    - devops-test
  image: curlimages/curl:8.00.1
  script:
    - sh scripts/ci-notify.sh ✅
  rules:
    - when: on_success

notify_failure:
  stage: notify
  tags:
    - devops-test
  image: curlimages/curl:8.00.1
  script:
    - sh scripts/ci-notify.sh ❌
  rules:
    - when: on_failure

```

---

## 📮 Telegram Integration

1. Create Telegram Bot:
   - Message @BotFather with `/newbot`
   - Save bot token (`TG_BOT_TOKEN`)

2. Create Telegram Channel:
   - Add your bot as admin
   - Get Channel ID using @getmyid_bot
   - Save channel ID (`TG_CHAT_ID`)

3. Add variables to GitLab:
   - Project Settings -> CI/CD -> Variables
   - Add `TG_BOT_TOKEN` and `TG_CHAT_ID`

4. Test notification:
```bash
curl -X POST https://api.telegram.org/<TG_BOT_TOKEN>/sendMessage \
  -d "chat_id=<TG_CHAT_ID>" \
  -d "text=Hello from the Telegram API!"
```

---

## 🚀 Deployment

1. Configure git remote:
```bash
git remote remove origin
git remote add origin http://<YOUR_SERVER_IP>:8929/root/tz.git
```

2. Push code:
```bash
git add .
git commit -am "Initial commit"
git push --set-upstream origin main
```

3. Monitor pipeline in GitLab:
   - Go to CI/CD -> Pipelines
   - Successful pipeline will show ✅ in Telegram
![Pasted image 20250408001048](https://github.com/user-attachments/assets/8c3428d0-8198-4363-8a47-a3ee0cb82c53)
![Pasted image 20250408001103](https://github.com/user-attachments/assets/a4e850b9-1767-414c-9bda-cbf66fa30006)


---

## 🔄 Troubleshooting
- Check container logs: `docker compose logs`
- Runner status: `docker exec runner gitlab-runner list`
- Force pipeline run: `git commit --allow-empty -m "Trigger pipeline"; git push`
```

**Note:** Replace all `<...>` placeholders with your actual values before execution.
