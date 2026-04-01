from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Bill

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    username = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ["id", "username", "email", "phone", "password", "first_name"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        # Use email as username if username not provided
        if not validated_data.get("username"):
            validated_data["username"] = validated_data["email"]
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="first_name")

    class Meta:
        model = User
        fields = ["id", "name", "email", "phone"]


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()


class BillSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bill
        fields = [
            "id",
            "total",
            "service_charge_percent",
            "items",
            "people",
            "assignments",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def create(self, validated_data):
        validated_data["user"] = self.context["request"].user
        return super().create(validated_data)
