from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    phone = models.CharField(max_length=20, blank=True, null=True)

    def __str__(self):
        return self.email or self.username


class Bill(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="bills")
    total = models.DecimalField(max_digits=10, decimal_places=2)
    service_charge_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    items = models.JSONField(default=list)
    people = models.JSONField(default=list)
    assignments = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Bill #{self.id} — {self.total} сом ({self.user})"
