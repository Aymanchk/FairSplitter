import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework_simplejwt.tokens import AccessToken
from django.contrib.auth import get_user_model

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope["url_route"]["kwargs"]["room_id"]
        self.room_group_name = f"chat_{self.room_id}"

        # Authenticate from query string token
        query_string = self.scope.get("query_string", b"").decode()
        token = dict(p.split("=", 1) for p in query_string.split("&") if "=" in p).get("token")

        if not token:
            await self.close()
            return

        try:
            access = AccessToken(token)
            self.user = await self.get_user(access["user_id"])
        except Exception:
            await self.close()
            return

        # Verify user is a participant
        is_participant = await self.check_participant()
        if not is_participant:
            await self.close()
            return

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, "room_group_name"):
            await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        text = data.get("text", "").strip()
        if not text:
            return

        message = await self.save_message(text)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": {
                    "id": message["id"],
                    "sender": message["sender"],
                    "text": message["text"],
                    "created_at": message["created_at"],
                    "is_read": message["is_read"],
                },
            },
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event["message"]))

    @database_sync_to_async
    def get_user(self, user_id):
        return User.objects.get(id=user_id)

    @database_sync_to_async
    def check_participant(self):
        from .models import ChatRoom
        return ChatRoom.objects.filter(id=self.room_id, participants=self.user).exists()

    @database_sync_to_async
    def save_message(self, text):
        from .models import Message, ChatRoom
        from .serializers import MessageSerializer

        room = ChatRoom.objects.get(id=self.room_id)
        msg = Message.objects.create(room=room, sender=self.user, text=text)
        return {
            "id": msg.id,
            "sender": {
                "id": self.user.id,
                "name": self.user.first_name,
                "email": self.user.email,
                "phone": self.user.phone,
                "avatar": self.user.avatar.url if self.user.avatar else None,
            },
            "text": msg.text,
            "created_at": msg.created_at.isoformat(),
            "is_read": msg.is_read,
        }
