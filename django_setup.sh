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
echo ""
echo "[3/8] Installing packages..."
pip install --quiet django djangorestframework pillow
echo "Installed: django, djangorestframework, pillow"

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
    phone = models.CharField(max_length=20, blank=True)
    image = models.ImageField(upload_to='users/', blank=True, null=True)

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
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .models import CustomUser


class SignUpForm(UserCreationForm):
    email = forms.EmailField(
        required=False,
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Email address'
        })
    )
    phone = forms.CharField(
        max_length=20,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Phone number'
        })
    )

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'phone', 'password1', 'password2']
        widgets = {
            'username': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Username',
                'autofocus': True
            }),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Password'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Confirm password'
        })

    def save(self, commit=True):
        user = super().save(commit=False)
        user.email = self.cleaned_data.get('email', '')
        user.phone = self.cleaned_data.get('phone', '')
        if commit:
            user.save()
        return user


class SignInForm(AuthenticationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Username',
            'autofocus': True
        })
        self.fields['password'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Password'
        })
EOF

# views.py
cat > "$appname/views.py" << 'EOF'
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from .forms import SignUpForm, SignInForm


def signup(request):
    form = SignUpForm(request.POST or None)
    if request.method == 'POST':
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('home')
    return render(request, 'signup.html', {'form': form})


def signin(request):
    form = SignInForm(request, data=request.POST or None)
    if request.method == 'POST':
        if form.is_valid():
            login(request, form.get_user())
            return redirect('home')
    return render(request, 'signin.html', {'form': form})


def signout(request):
    logout(request)
    return redirect('signin')


@login_required(login_url='signin')
def home(request):
    return render(request, 'home.html')
EOF

# urls.py (app)
cat > "$appname/urls.py" << 'EOF'
from django.urls import path
from .views import *

urlpatterns = [
    path('',         home,    name='home'),
    path('signup/',  signup,  name='signup'),
    path('signin/',  signin,  name='signin'),
    path('signout/', signout, name='signout'),
]
EOF

# ── Step 8: Templates ─────────────────────────────────────────────────────────
echo ""
echo "[8/8] Writing templates..."

# master/base.html
cat > "$appname/templates/master/base.html" << 'EOF'
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{% block title %}MyApp{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .navbar-brand { font-weight: bold; font-size: 1.4rem; }
        footer { background-color: #212529; color: #adb5bd; }
        .errorlist { list-style: none; padding: 0; margin: 4px 0 0; color: #dc3545; font-size: 0.875em; }
    </style>
    {% block extra_css %}{% endblock %}
</head>
<body>

{% include 'master/nav.html' %}
{% include 'master/message.html' %}

<main class="py-4">
    {% block content %}{% endblock %}
</main>

<footer class="py-3 mt-5">
    <div class="container text-center">
        <small>&copy; 2025 MyApp. All rights reserved.</small>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
{% block extra_js %}{% endblock %}
</body>
</html>
EOF

# master/nav.html
cat > "$appname/templates/master/nav.html" << 'EOF'
<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow">
    <div class="container">
        <a class="navbar-brand" href="{% url 'home' %}">🚀 MyApp</a>
        <button class="navbar-toggler" type="button"
                data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                {% if user.is_authenticated %}
                <li class="nav-item">
                    <a class="nav-link {% if request.resolver_match.url_name == 'home' %}active{% endif %}"
                       href="{% url 'home' %}">🏠 Home</a>
                </li>
                {% endif %}
            </ul>
            <ul class="navbar-nav ms-auto">
                {% if user.is_authenticated %}
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
                        👤 {{ user.username }}
                    </a>
                    <ul class="dropdown-menu dropdown-menu-end">
                        <li><span class="dropdown-item-text text-muted small">{{ user.email }}</span></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item text-danger" href="{% url 'signout' %}">🚪 Sign Out</a></li>
                    </ul>
                </li>
                {% else %}
                <li class="nav-item">
                    <a class="nav-link {% if request.resolver_match.url_name == 'signin' %}active{% endif %}"
                       href="{% url 'signin' %}">Sign In</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link {% if request.resolver_match.url_name == 'signup' %}active{% endif %}"
                       href="{% url 'signup' %}">Sign Up</a>
                </li>
                {% endif %}
            </ul>
        </div>
    </div>
</nav>
EOF

# master/message.html
cat > "$appname/templates/master/message.html" << 'EOF'
{% if messages %}
<div class="container mt-3">
    {% for message in messages %}
    <div class="alert alert-{{ message.tags }} alert-dismissible fade show" role="alert">
        {{ message }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    {% endfor %}
</div>
{% endif %}
EOF

# home.html
cat > "$appname/templates/home.html" << 'EOF'
{% extends 'master/base.html' %}
{% block title %}Home{% endblock %}
{% block content %}
<div class="container">
    <div class="card shadow mb-4">
        <div class="card-body p-4">
            <h2>👋 Welcome, {{ user.username }}!</h2>
            <p class="text-muted mb-1"><strong>Email:</strong> {{ user.email|default:"Not set" }}</p>
            <p class="text-muted mb-0"><strong>Joined:</strong> {{ user.date_joined|date:"d M Y" }}</p>
        </div>
    </div>
    <div class="row g-3">
        <div class="col-md-4">
            <div class="card text-white bg-primary shadow">
                <div class="card-body text-center py-4">
                    <h3>📊</h3><h5>Stats</h5><p class="mb-0">Coming Soon</p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-white bg-success shadow">
                <div class="card-body text-center py-4">
                    <h3>✅</h3><h5>Tasks</h5><p class="mb-0">Coming Soon</p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-white bg-warning shadow">
                <div class="card-body text-center py-4">
                    <h3>🔔</h3><h5>Alerts</h5><p class="mb-0">Coming Soon</p>
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}
EOF

# signup.html
cat > "$appname/templates/signup.html" << 'EOF'
{% extends 'master/base.html' %}
{% block title %}Sign Up{% endblock %}
{% block content %}
<div class="container">
    <div class="col-md-6 col-lg-5 mx-auto">
        <div class="card shadow p-4">
            <h2 class="mb-4 text-center">Create Account</h2>
            {% if form.non_field_errors %}
            <div class="alert alert-danger">{{ form.non_field_errors }}</div>
            {% endif %}
            <form method="POST" novalidate>
                {% csrf_token %}
                <div class="mb-3">
                    <label class="form-label fw-semibold">Username</label>
                    {{ form.username }}{{ form.username.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Email</label>
                    {{ form.email }}{{ form.email.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Phone</label>
                    {{ form.phone }}{{ form.phone.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Password</label>
                    {{ form.password1 }}{{ form.password1.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Confirm Password</label>
                    {{ form.password2 }}{{ form.password2.errors }}
                </div>
                <button class="btn btn-primary w-100 py-2">Sign Up</button>
            </form>
            <p class="mt-3 text-center text-muted">
                Already have an account? <a href="{% url 'signin' %}">Sign In</a>
            </p>
        </div>
    </div>
</div>
{% endblock %}
EOF

# signin.html
cat > "$appname/templates/signin.html" << 'EOF'
{% extends 'master/base.html' %}
{% block title %}Sign In{% endblock %}
{% block content %}
<div class="container">
    <div class="col-md-5 col-lg-4 mx-auto">
        <div class="card shadow p-4">
            <h2 class="mb-4 text-center">Welcome Back</h2>
            {% if form.non_field_errors %}
            <div class="alert alert-danger">{{ form.non_field_errors }}</div>
            {% endif %}
            <form method="POST" novalidate>
                {% csrf_token %}
                <div class="mb-3">
                    <label class="form-label fw-semibold">Username</label>
                    {{ form.username }}{{ form.username.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Password</label>
                    {{ form.password }}{{ form.password.errors }}
                </div>
                <button class="btn btn-success w-100 py-2">Sign In</button>
            </form>
            <p class="mt-3 text-center text-muted">
                No account? <a href="{% url 'signup' %}">Sign Up</a>
            </p>
        </div>
    </div>
</div>
{% endblock %}
EOF

# ── Settings & URLs ───────────────────────────────────────────────────────────
SETTINGS="$project/settings.py"
sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    '$appname',/" "$SETTINGS"

cat >> "$SETTINGS" << EOF

AUTH_USER_MODEL = '$appname.CustomUser'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

STATICFILES_DIRS = [BASE_DIR / 'static']

LOGIN_URL = 'signin'
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
echo "  source \"$ROOT/env/Scripts/activate\""
echo "  python manage.py runserver"
echo "======================================="
echo ""
python manage.py runserver

echo "=================================="
echo "   DJANGO AUTH GENERATOR v10.0"
echo "   Bash - Django Forms"
echo "=================================="
echo ""
read -p "Project Name : " project
read -p "App Name     : " appname
echo ""

ROOT=$(pwd)

# ── Step 1: Virtual Environment Create ────────────────────────────────────────
echo "[1/8] Creating virtual environment..."
python -m venv env
echo "venv created."

# ── Step 2: Activate ──────────────────────────────────────────────────────────
echo ""
echo "[2/8] Activating virtual environment..."
source $ROOT/env/bin/activate
echo "Activated: $(which python)"

# ── Step 3: Install Packages ──────────────────────────────────────────────────
echo ""
echo "[3/8] Installing packages..."
pip install --quiet django djangorestframework pillow
echo "Installed: django, djangorestframework, pillow"

# ── Step 4: startproject ──────────────────────────────────────────────────────
echo ""
echo "[4/8] Creating project..."
django-admin startproject $project
cd $ROOT/$project
echo "Project created: $project"

# ── Step 5: startapp ──────────────────────────────────────────────────────────
echo ""
echo "[5/8] Creating app..."
python manage.py startapp $appname
echo "App created: $appname"

# ── Step 6: Folders ───────────────────────────────────────────────────────────
echo ""
echo "[6/8] Creating folders..."
mkdir -p $appname/templates/master
mkdir -p static
mkdir -p media
echo "Folders created."

# ── Step 7: Write Python Files ────────────────────────────────────────────────
echo ""
echo "[7/8] Writing app files..."

# models.py
cat > $appname/models.py << 'EOF'
from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    phone = models.CharField(max_length=20, blank=True)
    image = models.ImageField(upload_to='users/', blank=True, null=True)

    def __str__(self):
        return self.username
EOF

# admin.py
cat > $appname/admin.py << 'EOF'
from django.contrib import admin
from .models import CustomUser

admin.site.register(CustomUser)
EOF

# forms.py
cat > $appname/forms.py << 'EOF'
from django import forms
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .models import CustomUser


class SignUpForm(UserCreationForm):
    email = forms.EmailField(
        required=False,
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Email address'
        })
    )
    phone = forms.CharField(
        max_length=20,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Phone number'
        })
    )

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'phone', 'password1', 'password2']
        widgets = {
            'username': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Username',
                'autofocus': True
            }),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Password'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Confirm password'
        })

    def save(self, commit=True):
        user = super().save(commit=False)
        user.email = self.cleaned_data.get('email', '')
        user.phone = self.cleaned_data.get('phone', '')
        if commit:
            user.save()
        return user


class SignInForm(AuthenticationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Username',
            'autofocus': True
        })
        self.fields['password'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Password'
        })
EOF

# views.py
cat > $appname/views.py << 'EOF'
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from .forms import SignUpForm, SignInForm


def signup(request):
    form = SignUpForm(request.POST or None)
    if request.method == 'POST':
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('home')
    return render(request, 'signup.html', {'form': form})


def signin(request):
    form = SignInForm(request, data=request.POST or None)
    if request.method == 'POST':
        if form.is_valid():
            login(request, form.get_user())
            return redirect('home')
    return render(request, 'signin.html', {'form': form})


def signout(request):
    logout(request)
    return redirect('signin')


@login_required(login_url='signin')
def home(request):
    return render(request, 'home.html')
EOF

# urls.py
cat > $appname/urls.py << 'EOF'
from django.urls import path
from .views import *

urlpatterns = [
    path('',         home,    name='home'),
    path('signup/',  signup,  name='signup'),
    path('signin/',  signin,  name='signin'),
    path('signout/', signout, name='signout'),
]
EOF

# ── Step 8: Templates ─────────────────────────────────────────────────────────
echo ""
echo "[8/8] Writing templates..."

# master/base.html
cat > $appname/templates/master/base.html << 'EOF'
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{% block title %}MyApp{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .navbar-brand { font-weight: bold; font-size: 1.4rem; }
        footer { background-color: #212529; color: #adb5bd; }
        .errorlist { list-style: none; padding: 0; margin: 4px 0 0; color: #dc3545; font-size: 0.875em; }
    </style>
    {% block extra_css %}{% endblock %}
</head>
<body>

{% include 'master/nav.html' %}
{% include 'master/message.html' %}

<main class="py-4">
    {% block content %}{% endblock %}
</main>

<footer class="py-3 mt-5">
    <div class="container text-center">
        <small>&copy; 2025 MyApp. All rights reserved.</small>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
{% block extra_js %}{% endblock %}
</body>
</html>
EOF

# master/nav.html
cat > $appname/templates/master/nav.html << 'EOF'
<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow">
    <div class="container">
        <a class="navbar-brand" href="{% url 'home' %}">🚀 MyApp</a>
        <button class="navbar-toggler" type="button"
                data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                {% if user.is_authenticated %}
                <li class="nav-item">
                    <a class="nav-link {% if request.resolver_match.url_name == 'home' %}active{% endif %}"
                       href="{% url 'home' %}">🏠 Home</a>
                </li>
                {% endif %}
            </ul>
            <ul class="navbar-nav ms-auto">
                {% if user.is_authenticated %}
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
                        👤 {{ user.username }}
                    </a>
                    <ul class="dropdown-menu dropdown-menu-end">
                        <li><span class="dropdown-item-text text-muted small">{{ user.email }}</span></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item text-danger" href="{% url 'signout' %}">🚪 Sign Out</a></li>
                    </ul>
                </li>
                {% else %}
                <li class="nav-item">
                    <a class="nav-link {% if request.resolver_match.url_name == 'signin' %}active{% endif %}"
                       href="{% url 'signin' %}">Sign In</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link {% if request.resolver_match.url_name == 'signup' %}active{% endif %}"
                       href="{% url 'signup' %}">Sign Up</a>
                </li>
                {% endif %}
            </ul>
        </div>
    </div>
</nav>
EOF

# master/message.html
cat > $appname/templates/master/message.html << 'EOF'
{% if messages %}
<div class="container mt-3">
    {% for message in messages %}
    <div class="alert alert-{{ message.tags }} alert-dismissible fade show" role="alert">
        {{ message }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    {% endfor %}
</div>
{% endif %}
EOF

# home.html
cat > $appname/templates/home.html << 'EOF'
{% extends 'master/base.html' %}
{% block title %}Home{% endblock %}
{% block content %}
<div class="container">
    <div class="card shadow mb-4">
        <div class="card-body p-4">
            <h2>👋 Welcome, {{ user.username }}!</h2>
            <p class="text-muted mb-1"><strong>Email:</strong> {{ user.email|default:"Not set" }}</p>
            <p class="text-muted mb-0"><strong>Joined:</strong> {{ user.date_joined|date:"d M Y" }}</p>
        </div>
    </div>
    <div class="row g-3">
        <div class="col-md-4">
            <div class="card text-white bg-primary shadow">
                <div class="card-body text-center py-4">
                    <h3>📊</h3><h5>Stats</h5><p class="mb-0">Coming Soon</p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-white bg-success shadow">
                <div class="card-body text-center py-4">
                    <h3>✅</h3><h5>Tasks</h5><p class="mb-0">Coming Soon</p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-white bg-warning shadow">
                <div class="card-body text-center py-4">
                    <h3>🔔</h3><h5>Alerts</h5><p class="mb-0">Coming Soon</p>
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}
EOF

# signup.html
cat > $appname/templates/signup.html << 'EOF'
{% extends 'master/base.html' %}
{% block title %}Sign Up{% endblock %}
{% block content %}
<div class="container">
    <div class="col-md-6 col-lg-5 mx-auto">
        <div class="card shadow p-4">
            <h2 class="mb-4 text-center">Create Account</h2>

            {% if form.non_field_errors %}
            <div class="alert alert-danger">
                {{ form.non_field_errors }}
            </div>
            {% endif %}

            <form method="POST" novalidate>
                {% csrf_token %}
                <div class="mb-3">
                    <label class="form-label fw-semibold">Username</label>
                    {{ form.username }}
                    {{ form.username.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Email</label>
                    {{ form.email }}
                    {{ form.email.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Phone</label>
                    {{ form.phone }}
                    {{ form.phone.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Password</label>
                    {{ form.password1 }}
                    {{ form.password1.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Confirm Password</label>
                    {{ form.password2 }}
                    {{ form.password2.errors }}
                </div>
                <button class="btn btn-primary w-100 py-2">Sign Up</button>
            </form>

            <p class="mt-3 text-center text-muted">
                Already have an account? <a href="{% url 'signin' %}">Sign In</a>
            </p>
        </div>
    </div>
</div>
{% endblock %}
EOF

# signin.html
cat > $appname/templates/signin.html << 'EOF'
{% extends 'master/base.html' %}
{% block title %}Sign In{% endblock %}
{% block content %}
<div class="container">
    <div class="col-md-5 col-lg-4 mx-auto">
        <div class="card shadow p-4">
            <h2 class="mb-4 text-center">Welcome Back</h2>

            {% if form.non_field_errors %}
            <div class="alert alert-danger">
                {{ form.non_field_errors }}
            </div>
            {% endif %}

            <form method="POST" novalidate>
                {% csrf_token %}
                <div class="mb-3">
                    <label class="form-label fw-semibold">Username</label>
                    {{ form.username }}
                    {{ form.username.errors }}
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Password</label>
                    {{ form.password }}
                    {{ form.password.errors }}
                </div>
                <button class="btn btn-success w-100 py-2">Sign In</button>
            </form>

            <p class="mt-3 text-center text-muted">
                No account? <a href="{% url 'signup' %}">Sign Up</a>
            </p>
        </div>
    </div>
</div>
{% endblock %}
EOF

# ── Settings & URLs ───────────────────────────────────────────────────────────
SETTINGS="$project/settings.py"
sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    '$appname',/" $SETTINGS

cat >> $SETTINGS << EOF

AUTH_USER_MODEL = '$appname.CustomUser'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

STATICFILES_DIRS = [BASE_DIR / 'static']

LOGIN_URL = 'signin'
LOGIN_REDIRECT_URL = 'home'
LOGOUT_REDIRECT_URL = 'signin'
EOF

cat > $project/urls.py << EOF
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
echo "  ../env/"
echo "  $project/              <- you are here"
echo "  +-- $project/"
echo "  |   +-- settings.py"
echo "  |   +-- urls.py"
echo "  +-- $appname/"
echo "  |   +-- models.py"
echo "  |   +-- forms.py"
echo "  |   +-- views.py"
echo "  |   +-- urls.py"
echo "  |   +-- templates/"
echo "  |       +-- home.html"
echo "  |       +-- signin.html"
echo "  |       +-- signup.html"
echo "  |       +-- master/"
echo "  |           +-- base.html"
echo "  |           +-- nav.html"
echo "  |           +-- message.html"
echo "  +-- static/"
echo "  +-- media/"
echo "  +-- manage.py"
echo ""
echo "  Superuser -> admin / 1"
echo "  http://127.0.0.1:8000"
echo "  http://127.0.0.1:8000/admin"
echo ""
echo "  Next time:"
echo "  source ../env/bin/activate"
echo "  python manage.py runserver"
echo "======================================="
echo ""
python manage.py runserver

