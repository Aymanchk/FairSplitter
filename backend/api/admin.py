from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Bill


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ["email", "first_name", "phone", "date_joined"]
    fieldsets = UserAdmin.fieldsets + (
        ("Дополнительно", {"fields": ("phone",)}),
    )


@admin.register(Bill)
class BillAdmin(admin.ModelAdmin):
    list_display = ["id", "user", "total", "service_charge_percent", "created_at"]
    list_filter = ["created_at"]
    readonly_fields = ["created_at"]
