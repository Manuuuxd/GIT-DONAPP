from rest_framework import serializers
from .models import Appointment, DonationCenter

class DonationCenterSerializer(serializers.ModelSerializer):
    class Meta:
        model = DonationCenter
        fields = ["id", "name", "address", "comuna", "phone"]

class AppointmentSerializer(serializers.ModelSerializer):
    center = DonationCenterSerializer(read_only=True)
    center_id = serializers.PrimaryKeyRelatedField(
        queryset=DonationCenter.objects.all(),
        source="center",
        write_only=True
    )

    class Meta:
        model = Appointment
        fields = ["id", "rut", "email", "date", "time", "center", "center_id", "status", "cancellation_reason"]
