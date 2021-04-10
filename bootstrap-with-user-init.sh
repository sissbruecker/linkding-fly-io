#!/usr/bin/env bash

# Create data folder if it does not exist
mkdir -p data

# Run database migration
python manage.py migrate

cat <<EOF | python manage.py shell
from django.contrib.auth import get_user_model

User = get_user_model()  # get the currently active user model,

user = User.objects.create_user(os.getenv('LINKDING_USER_NAME'), password=os.getenv('LINKDING_USER_PASS'))
user.is_superuser = True
user.is_staff = True
user.save()
EOF

./bootstrap.sh
