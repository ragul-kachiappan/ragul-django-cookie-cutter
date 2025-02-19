# ragul-django-cookie-cutter
My interpretation of Django template that can be used for projects.
AI native boilerplate to provide better context for AI tools like copilot, cursor, etc.
This template will also include sample for DevOps in terraform, Ansible, CI, Docker, etc.

# Things that need to added

1. Basic Stuff
- [x] Basic environment setup with uv, mise, pre-commit stuff, etc
- [ ] dev containers setup for unified dev environment
- [x] Basic Django setup
- [x] Linting, formatting
- [ ] Terraform
- [ ] Ansible playbook for configuration deployment steps along with nginx, [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) for initial VM setup (test it with multipass)
- [ ] Github workflows for deployment, checks, tests, etc
- [x] Dockerfile with multistage setup
- [x] Dockercompose to include postgres, nginx, chromadb and redis
- [ ] Optimization in nginx, gunicorn setup

2. Web App related
- [ ] JWT setup
- [ ] API Docs setup
- [ ] JSON logging setup
- [ ] Test suite
- [ ] AWS SDK integration for S3 and other common services

3. Advanced Web stuff
- [ ] Background worker
- [ ] Websocket
- [ ] Caching

3. Best practices (some opinionated tribal knowledge)
- [ ] How to structure the project
- [ ] Gotcha's to avoid
- [ ] Git workflow for multiple environments
- [ ] How to solve certain issues (merge conflicts, migration blockers, etc)

4. AI assistance
- [ ] Cursor project rules, style guide
