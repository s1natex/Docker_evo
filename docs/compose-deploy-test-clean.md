
pip install -r app/pass-gen/requirements.txt

python ./scripts/run_unit.py

docker compose up --build

http://localhost:3000/

python ./scripts/run_e2e.py

docker compose down