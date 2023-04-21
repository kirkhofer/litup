#!/bin/sh

echo ""
echo "Loading azd .env file from current environment"
echo ""

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

if [ $? -ne 0 ]; then
    echo "Failed to load environment variables from azd environment"
    exit $?
fi

echo 'Creating python virtual environment "web/web_env"'
python -m venv web/web_env

echo ""
echo "Restoring web python packages"
echo ""

cd web
./web_env/bin/python -m pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to restore web python packages"
    exit $?
fi

# echo ""
# echo "Restoring frontend npm packages"
# echo ""

# cd ../frontend
# npm install
# if [ $? -ne 0 ]; then
#     echo "Failed to restore frontend npm packages"
#     exit $?
# fi

# echo ""
# echo "Building frontend"
# echo ""

# npm run build
# if [ $? -ne 0 ]; then
#     echo "Failed to build frontend"
#     exit $?
# fi

echo ""
echo "Starting web"
echo ""

cd ../web
xdg-open http://127.0.0.1:5000
./web_env/bin/python streamlit run app.py
# ./web_env/bin/python ./app.py
if [ $? -ne 0 ]; then
    echo "Failed to start web"
    exit $?
fi
