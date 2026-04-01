from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .models import Bill
from .serializers import (
    RegisterSerializer,
    UserSerializer,
    LoginSerializer,
    BillSerializer,
)

User = get_user_model()


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
    }


@api_view(["POST"])
@permission_classes([AllowAny])
def register_view(request):
    serializer = RegisterSerializer(data={
        "email": request.data.get("email"),
        "first_name": request.data.get("name", ""),
        "phone": request.data.get("phone"),
        "password": request.data.get("password"),
    })
    if serializer.is_valid():
        user = serializer.save()
        tokens = get_tokens_for_user(user)
        return Response(
            {
                "user": UserSerializer(user).data,
                "token": tokens["access"],
                "refresh": tokens["refresh"],
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(
        {"error": next(iter(serializer.errors.values()))[0]},
        status=status.HTTP_400_BAD_REQUEST,
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {"error": "Введите email и пароль"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    email = serializer.validated_data["email"]
    password = serializer.validated_data["password"]

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {"error": "Неверный email или пароль"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if not user.check_password(password):
        return Response(
            {"error": "Неверный email или пароль"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    tokens = get_tokens_for_user(user)
    return Response({
        "user": UserSerializer(user).data,
        "token": tokens["access"],
        "refresh": tokens["refresh"],
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def profile_view(request):
    return Response({"user": UserSerializer(request.user).data})


class BillListCreateView(generics.ListCreateAPIView):
    serializer_class = BillSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Bill.objects.filter(user=self.request.user)


class BillDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = BillSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Bill.objects.filter(user=self.request.user)
