#!/bin/bash
clear#!/bin/bash
clear
echo "=================================="
echo "   DJANGO AUTH GENERATOR v11.0"
echo "   Bash - Django Forms"
echo "=================================="
echo ""
read -p "Project Name : " project
read -p "App Name     : " appname
echo ""

# quotes দিয়ে ROOT save — space সহ path handle করবে
ROOT="$(pwd)"

# ── Step 1: Virtual Environment Create ────────────────────────────────────────
echo "[1/8] Creating virtual environment..."
python -m venv "$ROOT/env"
echo "venv created."

# ── Step 2: Activate + absolute path ──────────────────────────────────────────
echo ""
echo "[2/8] Activating virtual environment..."

# Windows Git Bash এ activate script আলাদা জায়গায়
if [ -f "$ROOT/env/Scripts/activate" ]; then
    source "$ROOT/env/Scripts/activate"   # Git Bash / Windows
else
    source "$ROOT/env/bin/activate"       # Linux / Mac / Termux
fi

echo "Activated: $(which python)"

# ── Step 3: Install Packages ──────────────────────────────────────────────────
echo "  source \"$ROOT/env/Scripts/activate\""
echo ""
echo "[3/8] Installing packages..."
pip install --quiet django djangorestframework pillow crispy-bootstrap5
echo "Installed: django, djangorestframework, pillow, crispy-bootstrap5"

# ── Step 4: startproject ──────────────────────────────────────────────────────
echo ""
echo "[4/8] Creating project..."
django-admin startproject "$project" "$ROOT/$project"
cd "$ROOT/$project"
echo "Project created: $project"

# ── Step 5: startapp ──────────────────────────────────────────────────────────
echo ""
echo "[5/8] Creating app..."
python manage.py startapp "$appname"
echo "App created: $appname"

# ── Step 6: Folders ───────────────────────────────────────────────────────────
echo ""
echo "[6/8] Creating folders..."
mkdir -p "$appname/templates/master"
mkdir -p "static"
mkdir -p "media"
echo "Folders created."

# ── Step 7: Write Python Files ────────────────────────────────────────────────
echo ""
echo "[7/8] Writing app files..."

# models.py
cat > "$appname/models.py" << 'EOF'
from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    USER_TYPE = [
        ('Recruiter','Recruiter'),
        ('Jobseeker','Jobseeker'),
    ]
    display_name = models.CharField(max_length=100,null=True)
    user_type = models.CharField(choices=USER_TYPE,max_length=100,null=True)


    def __str__(self):
        return self.username
EOF

# admin.py
cat > "$appname/admin.py" << 'EOF'
from django.contrib import admin
from .models import CustomUser

admin.site.register(CustomUser)
EOF

# forms.py
cat > "$appname/forms.py" << 'EOF'
from django import forms
from .models import *
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm

class SignUpForm(UserCreationForm):

    class Meta:
        model = CustomUser
        fields = ['username','display_name','email','user_type']

    

class SignInForm(AuthenticationForm):
    pass

EOF

# views.py
cat > "$appname/views.py" << 'EOF'
from django.shortcuts import render,redirect,get_object_or_404
from django.contrib.auth import logout,login
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from .forms import *
from .models import *

# Create your views here.


def signUpPage(request):

    if request.method == 'POST':
        form_data = SignUpForm(request.POST)
        if form_data.is_valid():
            form_data.save()
            messages.success(request,'Sign Up Success!')
            return redirect('signInPage')

    form_data = SignUpForm()

    context = {
        'form_data' : form_data,
        'form_title' : 'Sign Up Page!',
        'form_btn' : 'Sign Up',
    }

    return render(request,'master/base_form.html',context)

def signInPage(request):

    if request.method == 'POST':
        form_data = SignInForm(request,data = request.POST)
        if form_data.is_valid():
            login(request,form_data.get_user())
            messages.success(request,'Sign In Success!')
            return redirect('dashboardPage')
    
    form_data = SignInForm()
    
    context = {
        'form_data' : form_data,
        'form_title' : 'Sign In Page!',
        'form_btn' : 'Sign In',
    }

    return render(request,'master/base_form.html',context)

@login_required
def signOutPage(request):
    logout(request)
    messages.success(request,'Sign Out Success!')
    return redirect('dashboardPage')

def dashboardPage(request):


    return render(request,'dashboard.html')
EOF

# urls.py (app)
cat > "$appname/urls.py" << 'EOF'
from django.urls import path
from .views import *

urlpatterns = [
    path('dashboardPage/',dashboardPage,name='dashboardPage'),
    path('',signInPage,name='signInPage'),
    path('signUpPage/',signUpPage,name='signUpPage'),
    path('signOutPage/',signOutPage,name='signOutPage'),
]
EOF

# ── Step 8: Templates ─────────────────────────────────────────────────────────
echo ""
echo "[8/8] Writing templates..."

# master/base.html
cat > "$appname/templates/master/base.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <!-- Required meta tags -->
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous" />

    <title>Hello, world!</title>
  </head>
  <body>
    {% include 'master/nav.html' %}

    <div class="container">
      {% include 'master/messages.html' %}
      {% block content %}

      {% endblock %}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-MrcW6ZMFYlzcLA8Nl+NtUVF0sA7MsXsP1UyJoMp4YLEuNSfAP+JcXn/tWtIaxVXM" crossorigin="anonymous"></script>
  </body>
</html>

EOF

# master/nav.html
cat > "$appname/templates/master/nav.html" << 'EOF'
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <div class="container">
    <a class="navbar-brand" href="#">JobPortal</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
          {% if request.user.is_authenticated %}
          <li class="nav-item">
            <a class="nav-link active" aria-current="page" href="{% url 'dashboardPage' %}">Dashboard</a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="">Profile</a>
          </li>
          {% endif %}

      </ul>

      <div class="d-flex">
        {% if request.user.is_authenticated %}
          <a href="{% url 'signOutPage' %}" class="btn btn-danger me-2">Sign Out</a>
        {% else %}
          <a href="{% url 'signInPage' %}" class="btn btn-info me-2">Sign In</a>
          <a href="{% url 'signUpPage' %}" class="btn btn-success me-2">Sign Up</a>
        {% endif %}
      </div>
    </div>
  </div>
</nav>
EOF

# master/messages.html
cat > "$appname/templates/master/messages.html" << 'EOF'
{% if messages %}
{% for message in messages %}

<div class="alert alert-success" role="alert">
 {{message}}
</div>


{% endfor %}



{% endif %}
EOF

# dashboard.html
cat > "$appname/templates/dashboard.html" << 'EOF'
{% extends 'master/base.html' %}
{% block content %}
  <h1 class="text-center m-2">Dashboard</h1>
{% endblock %}
EOF

# signup.html
cat > "$appname/templates/master/base_form.html" << 'EOF'
{% extends 'master/base.html' %}
{% block content %}
{% load crispy_forms_tags %}
  <h1 class="text-center m-2">{{ form_title }}</h1>

  <form action="" method="post" enctype="multipart/form-data">
    {% csrf_token %}
    {{form_data | crispy}}

    <button type="submit" class="btn btn-primary">{{ form_btn }}</button>
  </form>
{% endblock %}

EOF

# # signin.html
# cat > "$appname/templates/signin.html" << 'EOF'
# {% extends 'master/base.html' %}
# {% block title %}Sign In{% endblock %}
# {% block content %}
# <div class="container">
#     <div class="col-md-5 col-lg-4 mx-auto">
#         <div class="card shadow p-4">
#             <h2 class="mb-4 text-center">Welcome Back</h2>
#             {% if form.non_field_errors %}
#             <div class="alert alert-danger">{{ form.non_field_errors }}</div>
#             {% endif %}
#             <form method="POST" novalidate>
#                 {% csrf_token %}
#                 <div class="mb-3">
#                     <label class="form-label fw-semibold">Username</label>
#                     {{ form.username }}{{ form.username.errors }}
#                 </div>
#                 <div class="mb-3">
#                     <label class="form-label fw-semibold">Password</label>
#                     {{ form.password }}{{ form.password.errors }}
#                 </div>
#                 <button class="btn btn-success w-100 py-2">Sign In</button>
#             </form>
#             <p class="mt-3 text-center text-muted">
#                 No account? <a href="{% url 'signup' %}">Sign Up</a>
#             </p>
#         </div>
#     </div>
# </div>
# {% endblock %}
# EOF

# ── Settings & URLs ───────────────────────────────────────────────────────────
SETTINGS="$project/settings.py"
# Add app + crispy + DRF to INSTALLED_APPS
sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    '$appname',\n    'crispy_forms',\n    'crispy_bootstrap5',\n    'rest_framework',/" "$SETTINGS"

cat >> "$SETTINGS" << EOF

AUTH_USER_MODEL = '$appname.CustomUser'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

STATICFILES_DIRS = [BASE_DIR / 'static']

CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap5"
CRISPY_TEMPLATE_PACK = "bootstrap5"

LOGIN_URL = 'signInPage'
LOGIN_REDIRECT_URL = 'home'
LOGOUT_REDIRECT_URL = 'signin'
EOF

cat > "$project/urls.py" << EOF
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('',       include('$appname.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATICFILES_DIRS[0])
EOF

# ── Migrations ────────────────────────────────────────────────────────────────
echo ""
echo "Running migrations..."
python manage.py makemigrations
python manage.py migrate

# ── Auto Superuser ────────────────────────────────────────────────────────────
echo ""
echo "Creating superuser (admin / 1)..."
echo "from django.contrib.auth import get_user_model; U = get_user_model(); U.objects.filter(username='admin').exists() or U.objects.create_superuser('admin', 'admin@example.com', '1')" | python manage.py shell

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "======================================="
echo "  PROJECT READY!"
echo "======================================="
echo ""
echo "  Superuser -> admin / 1"
echo "  http://127.0.0.1:8000"
echo "  http://127.0.0.1:8000/admin"
echo ""
echo "  Next time (Git Bash):"
echo "  cd \"$ROOT/$project\""
echo "  python manage.py runserver"
echo "======================================="
echo ""
python manage.py runserver
