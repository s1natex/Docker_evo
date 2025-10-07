# Setup and Testing on Local Docker-Compose
- ### Run Unit Tests from Project Root:
```
pip install -r app/pass-gen/requirements.txt
python ./scripts/run_unit.py
```
- ### Run the Web App with Docker-Compose:
```
docker compose up --build
```
- ### Access the Frontend URL: `http://localhost:3000/`
- ### Run the Runtime Tests from Project Root:
```
python ./scripts/run_e2e.py
```
- ### Clean Up:
```
docker compose down
```
