# ================================== #
#   DJANGO AUTH GENERATOR v9.0       #
#   PowerShell - Django Forms        #
# ================================== #

Clear-Host
Write-Host "=================================="
Write-Host "   DJANGO AUTH GENERATOR v9.0"
Write-Host "   PowerShell - Django Forms"
Write-Host "=================================="
Write-Host ""
$project = Read-Host "Project Name"
$appname = Read-Host "App Name"
Write-Host ""

# script এর root path save
$root = Get-Location

# ── Step 1: Virtual Environment ───────────────────────────────────────────────
Write-Host "[1/8] Creating virtual environment..."
python -m venv env

$py  = "$root\env\Scripts\python.exe"
$pip = "$root\env\Scripts\pip.exe"
$dja = "$root\env\Scripts\django-admin.exe"

Write-Host "venv created."

# ── Step 2: Install Packages ──────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/8] Installing packages..."
& $pip install --quiet django djangorestframework pillow
Write-Host "Done."

# ── Step 3: startproject ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/8] Creating project..."
& $dja startproject $project

Set-Location "$root\$project"

# ── Step 4: startapp ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/8] Creating app..."
& $py manage.py startapp $appname

# ── Step 5: Folders ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/8] Creating folders..."
New-Item -ItemType Directory -Force -Path "$appname\templates\master" | Out-Null
New-Item -ItemType Directory -Force -Path "static"                    | Out-Null
New-Item -ItemType Directory -Force -Path "media"                     | Out-Null
Write-Host "Folders created."

# ── Step 6: Write Python Files ────────────────────────────────────────────────
Write-Host ""
Write-Host "[6/8] Writing app files..."

# models.py
@"
from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    phone = models.CharField(max_length=20, blank=True)
    image = models.ImageField(upload_to='users/', blank=True, null=True)

    def __str__(self):
        return self.username
"@ | Set-Content "$appname\models.py" -Encoding UTF8

# admin.py
@"
from django.contrib import admin
from .models import CustomUser

admin.site.register(CustomUser)
"@ | Set-Content "$appname\admin.py" -Encoding UTF8

# forms.py
@"
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
"@ | Set-Content "$appname\forms.py" -Encoding UTF8

# views.py
@"
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
"@ | Set-Content "$appname\views.py" -Encoding UTF8

# urls.py
@"
from django.urls import path
from .views import *

urlpatterns = [
    path('',         home,    name='home'),
    path('signup/',  signup,  name='signup'),
    path('signin/',  signin,  name='signin'),
    path('signout/', signout, name='signout'),
]
"@ | Set-Content "$appname\urls.py" -Encoding UTF8

# ── Step 7: Templates ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[7/8] Writing templates..."

# master/base.html
@"
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
"@ | Set-Content "$appname\templates\master\base.html" -Encoding UTF8

# master/nav.html
@"
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
"@ | Set-Content "$appname\templates\master\nav.html" -Encoding UTF8

# master/message.html
@"
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
"@ | Set-Content "$appname\templates\master\message.html" -Encoding UTF8

# home.html
@"
{% extends 'master/base.html' %}
{% block title %}Home{% endblock %}
{% block content %}
<div class="container">
    <div class="card shadow mb-4">
        <div class="card-body p-4">
            <h2>👋 Welcome, {{ user.username }}!</h2>
            <p class="text-muted mb-1"><strong>Email:</strong> {{ user.email|default:'Not set' }}</p>
            <p class="text-muted mb-0"><strong>Joined:</strong> {{ user.date_joined|date:'d M Y' }}</p>
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
"@ | Set-Content "$appname\templates\home.html" -Encoding UTF8

# signup.html
@"
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
"@ | Set-Content "$appname\templates\signup.html" -Encoding UTF8

# signin.html
@"
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
"@ | Set-Content "$appname\templates\signin.html" -Encoding UTF8

# ── Step 8: settings.py & urls.py ────────────────────────────────────────────
Write-Host ""
Write-Host "[8/8] Updating settings and urls..."

$settingsPath = "$project\settings.py"
$settings = Get-Content $settingsPath -Raw

$settings = $settings -replace "('django\.contrib\.staticfiles',)", "`$1`n    '$appname',"

$extra = @"


AUTH_USER_MODEL = '$appname.CustomUser'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

STATICFILES_DIRS = [BASE_DIR / 'static']

LOGIN_URL = 'signin'
LOGIN_REDIRECT_URL = 'home'
LOGOUT_REDIRECT_URL = 'signin'
"@

($settings + $extra) | Set-Content $settingsPath -Encoding UTF8

@"
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
"@ | Set-Content "$project\urls.py" -Encoding UTF8

# ── Migrations ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Running migrations..."
& $py manage.py makemigrations
& $py manage.py migrate

# ── Auto Superuser ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Creating superuser (admin / 1)..."
$cmd = "from django.contrib.auth import get_user_model; U = get_user_model(); U.objects.filter(username='admin').exists() or U.objects.create_superuser('admin', 'admin@example.com', '1')"
$cmd | & $py manage.py shell

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "======================================="
Write-Host "  PROJECT READY!"
Write-Host "======================================="
Write-Host ""
Write-Host "  ..\env\"
Write-Host "  $project\              <- you are here"
Write-Host "  +-- $project\"
Write-Host "  |   +-- settings.py"
Write-Host "  |   +-- urls.py"
Write-Host "  +-- $appname\"
Write-Host "  |   +-- models.py"
Write-Host "  |   +-- forms.py"
Write-Host "  |   +-- views.py"
Write-Host "  |   +-- urls.py"
Write-Host "  |   +-- templates\"
Write-Host "  |       +-- home.html"
Write-Host "  |       +-- signin.html"
Write-Host "  |       +-- signup.html"
Write-Host "  |       +-- master\"
Write-Host "  |           +-- base.html"
Write-Host "  |           +-- nav.html"
Write-Host "  |           +-- message.html"
Write-Host "  +-- static\"
Write-Host "  +-- media\"
Write-Host "  +-- manage.py"
Write-Host ""
Write-Host "  Superuser  ->  admin / 1"
Write-Host "  http://127.0.0.1:8000"
Write-Host "  http://127.0.0.1:8000/admin"
Write-Host ""
Write-Host "  Next time:"
Write-Host "  cd $project"
Write-Host "  ..\env\Scripts\python.exe manage.py runserver"
Write-Host "======================================="
Write-Host ""
& $py manage.py runserver
