
pip install -r app/pass-gen/requirements.txt

python ./scripts/run_unit.py

docker compose up --build

http://localhost:3000/



docker compose down